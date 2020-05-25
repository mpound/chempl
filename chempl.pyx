# distutils: language = c++

from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.map cimport map as cppmap
from libcpp.set cimport set as cppset
from libcpp.utility cimport pair
from myconsts import Consts
import datetime
import re
import numpy as np

cs = Consts()

cdef extern from "types.hpp" namespace "TYPES":

  cdef cppclass Reaction:
    int itype
    vector[string] sReactants, sProducts
    vector[double] abc, Trange
    double drdy[2]
    double rate
    double heat
    Reaction() except +
    Reaction(vector[string] sReactants,
             vector[string] sProducts,
             vector[double] abc,
             vector[double] Trange,
             int itype)

  cdef cppclass Species:
    cppmap[string, int] name2idx
    vector[string] idx2name
    cppmap[int, cppmap[string, int]] elementsSpecies
    cppmap[int, double] massSpecies, enthalpies,
    cppmap[int, double] vibFreqs, diffBarriers, quantMobilities
    cppset[int] gasSpecies, surfaceSpecies, mantleSpecies
    vector[double] abundances
    void allocate_abundances()

  cdef cppclass AuxData:
    double t_calc, k_eva_tot, k_ads_tot, mant_tot, surf_tot
    int n_surf2mant, n_mant2surf
    vector[Reaction] ads_reactions, eva_reactions


  cdef cppclass PhyParams:
    void prep_params()
    int from_file(string fname)
    void add_a_timedependency(string name,
        vector[double] ts, vector[double] vs)
    void remove_a_timedependency(string name)
    vector[string] get_timeDependency_names()

  ctypedef vector[Reaction] Reactions
  ctypedef cppmap[string, double] Elements
  ctypedef cppmap[int, int] ReactionTypes
  ctypedef double (*RateCalculator)(const double&, double *,
           Reaction&, const PhyParams&, const Species&, AuxData&)
  ctypedef cppmap[int, RateCalculator] RateCalculators

  cdef cppclass Chem_data:
    void add_reaction(Reaction rs)
    void modify_reaction(const int& iReact, const cppmap[string, vector[double]] &par)
    void clear_reactions()
    void find_duplicate_reactions()
    void set_phy_param(string name, double v)
    double get_phy_param(string name)
    cppmap[string, double] get_all_phy_params()
    void assort_reactions()
    void assignElementsToSpecies()
    void assignElementsToSpecies(Elements& elements)
    void calculateSpeciesMasses()
    void calculateSpeciesMasses(Elements& elements)
    void calculateSpeciesVibFreqs()
    void calculateSpeciesDiffBarriers()
    void calculateSpeciesQuantumMobilities()
    void calculateReactionHeat()
    void classifySpeciesByPhase()
    void allocate_y()
    void deallocate_y()
    double calculate_a_rate(double t, double *y, Reaction& r, int updatePhyParams)
    vector[pair[int, double]] getFormationReactionsWithRates(int iSpecies, double t, double*y)
    vector[pair[int, double]] getDestructionReactionsWithRates(int iSpecies, double t, double*y)
    Reactions reactions
    PhyParams physical_params
    Species species
    ReactionTypes reaction_types
    Chem_data* ptr
    RateCalculators rate_calculators
    vector[int] dupli
    AuxData auxdata
    double* y

  void update_phy_params(double t, PhyParams& p)
  cppmap[string, int] assignElementsToOneSpecies(string name, const Elements& elements)


cdef extern from "utils.hpp" namespace "UTILS":
  double interpol(const vector[double]& ts, const vector[double]& vs, double t)


cdef extern from "logistics.hpp" namespace "LOGIS":
  void load_reactions(const string& fname, Chem_data& cdata,
    int nReactants, int nProducts, int nABC, int lenSpeciesName,
    int lenABC, int nT, int lenT, int lenType, int rowlen_min)
  int loadInitialAbundances(Species& species, string fname)
  int loadSpeciesEnthalpies(Species& species, string fname)


cdef extern from "calculate_reaction_rate.hpp" namespace "CALC_RATE":
  void assignReactionHandlers(Chem_data&)
  void assignAReactionHandler(RateCalculators& rcs,
                              const RateCalculator& rc,
                              const int& itype)
  double rate_photodissociation_H2(
    const double& t,
    const double* y,
    Reaction& r,
    const PhyParams& p,
    const Species& s,
    AuxData& m)
  double arrhenius(const double &T, const vector[double] &abc,
                       const int &iS)

cdef extern from "rate_equation_lsode.hpp" namespace "RATE_EQ":
  cdef cppclass Updater_RE:
    void set_user_data(Chem_data* udata)
    void allocate_sparse()
    int initialize_solver(double reltol, double abstol, int mf, int LRW_F, int solver_id)
    void allocate_rsav_isav()
    void save_restore_common_block(int job)
    double update(double t, double dt, double* y)
    void set_solver_msg(int mflag)
    void set_solver_msg_lun(int lun)
    void set_MF(int i_)
    void set_IOPT(int i_)
    void set_ITOL(int i_)
    void set_ITASK(int i_)
    void set_ISTATE(int i_)
    void set_RTOL(double i_)
    void set_ATOL(double i_)

    int NEQ, ITOL, ITASK, ISTATE, IOPT, LRW, LIW, MF, NNZ
    double RTOL, ATOL


cdef class ChemModel:

  cdef Chem_data cdata
  cdef Updater_RE updater_re
  cdef public all_reactions

  def set_solver(self, rtol=1e-6, atol=1e-30, mf=21, LRW_F=6,
                 showmsg=1, msglun=6, solver_id=0):
    self.updater_re.set_user_data(self.cdata.ptr)
    self.updater_re.allocate_sparse()
    self.updater_re.initialize_solver(rtol, atol, mf, LRW_F, solver_id)
    self.updater_re.set_solver_msg(showmsg)
    self.updater_re.set_solver_msg_lun(msglun)
    self.updater_re.allocate_rsav_isav()
    self.cdata.allocate_y()

  def allocate_y(self):
    self.cdata.allocate_y()

  def deallocate_y(self):
    self.cdata.deallocate_y()

  def get_solver_internals(self):
    return {
      'NEQ':    self.updater_re.NEQ,
      'ITOL':   self.updater_re.ITOL,
      'ITASK':  self.updater_re.ITASK,
      'ISTATE': self.updater_re.ISTATE,
      'IOPT':   self.updater_re.IOPT,
      'LRW':    self.updater_re.LRW,
      'LIW':    self.updater_re.LIW,
      'MF':     self.updater_re.MF,
      'NNZ':    self.updater_re.NNZ,
      'RTOL':   self.updater_re.RTOL,
      'ATOL':   self.updater_re.ATOL}

  def save_common_block(self):
    self.updater_re.save_restore_common_block(job=1)

  def restore_common_block(self):
    self.updater_re.save_restore_common_block(job=2)

  def update(self, vector[double] y, double t, double dt, int istate=0, interruptMode=False):
    cdef int i
    cdef double t1

    self.updater_re.set_user_data(self.cdata.ptr)

    for i in range(self.updater_re.NEQ):
      self.cdata.y[i] = y[i]

    if istate != 0:
      self.updater_re.set_ISTATE(istate)
    if interruptMode and self.updater_re.ISTATE not in [0,1]:
      self.restore_common_block()
    if self.updater_re.ISTATE < 0:
      if self.updater_re.ISTATE in [-1, -4, -5]:
        self.updater_re.set_ISTATE(3)
      else:
        print('Unrecoverable error: ISTATE = ', self.updater_re.ISTATE)
        return

    t1 = self.updater_re.update(t, dt, self.cdata.y)

    if interruptMode and istate != 1:
      self.save_common_block()
    return t1, [self.cdata.y[i] for i in range(self.updater_re.NEQ)]

  def add_reaction(self,
                   vector[string] sReactants,
                   vector[string] sProducts,
                   vector[double] abc,
                   vector[double] Trange,
                   int itype):
    cdef Reaction rs
    rs = Reaction(sReactants, sProducts, abc, Trange, itype)
    self.cdata.add_reaction(rs)

  def modify_reaction(self, const int& iReact, const cppmap[string, vector[double]] &par):
    """modify_reaction(iReact, map[string, vector[double]])
    string: b"abc" or b"Trange"
    """
    self.cdata.modify_reaction(iReact, par)

  def add_reaction_by_dict(self, r):
    cdef Reaction rs
    rs = Reaction(r['reactants'], r['products'], r['abc'], r['Trange'], r['itype'])
    self.cdata.add_reaction(rs)

  def clear_reactions(self):
    self.cdata.clear_reactions()

  def find_duplicate_reactions(self):
    self.cdata.find_duplicate_reactions()

  def calculate_a_rate(self, double t, vector[double] y, int iReac, int updatePhyParams=False):
    """calculate_a_rate(t, y, iReac, updatePhyParams=False)"""
    for i in range(len(y)):
      self.cdata.y[i] = y[i]
    return self.cdata.calculate_a_rate(t, self.cdata.y, self.cdata.reactions[iReac], updatePhyParams)

  def getFormationReactionsWithRates(self, int iSpecies, double t, vector[double] y):
    for i in range(len(y)):
      self.cdata.y[i] = y[i]
    return self.cdata.getFormationReactionsWithRates(iSpecies, t, self.cdata.y)

  def getDestructionReactionsWithRates(self, int iSpecies, double t, vector[double] y):
    for i in range(len(y)):
      self.cdata.y[i] = y[i]
    return self.cdata.getDestructionReactionsWithRates(iSpecies, t, self.cdata.y)

  def set_phy_param(self, string name, double val):
    self.cdata.set_phy_param(name, val)
    self.cdata.physical_params.prep_params()

  def set_phy_param_from_file(self, string fname):
    self.cdata.physical_params.from_file(fname)
    self.cdata.physical_params.prep_params()

  def get_phy_param(self, string name):
    return self.cdata.get_phy_param(name)

  def set_phy_params_by_dict(self, d):
    for k in d:
      self.set_phy_param(k, d[k])
    self.cdata.physical_params.prep_params()

  def get_all_phy_params(self):
    return self.cdata.get_all_phy_params()

  def add_time_dependency(self, name, ts, vs):
    """add_phy_param_time_dependency(name, ts, vs)"""
    self.cdata.physical_params.add_a_timedependency(name, ts, vs)

  def remove_time_dependency(self, name):
    """remove_phy_param_time_dependency(name)"""
    self.cdata.physical_params.remove_a_timedependency(name)

  def get_time_dependency_names(self):
    """get_timeDependency_names()"""
    return self.cdata.physical_params.get_timeDependency_names()

  def update_phy_params(self, t):
    update_phy_params(t, self.cdata.physical_params)

  def assort_reactions(self):
    return self.cdata.assort_reactions()

  def assignElementsToSpecies(self, elements=None):
    if elements:
      self.cdata.assignElementsToSpecies(elements)
    else:
      self.cdata.assignElementsToSpecies()

  def calculateSpeciesMasses(self, elements=None):
    if elements:
      self.cdata.calculateSpeciesMasses(elements)
    else:
      self.cdata.calculateSpeciesMasses()

  def calculateSpeciesVibFreqs(self):
    self.cdata.calculateSpeciesVibFreqs()

  def calculateSpeciesDiffBarriers(self):
    self.cdata.calculateSpeciesDiffBarriers()

  def calculateSpeciesQuantumMobilities(self):
    self.cdata.calculateSpeciesQuantumMobilities()

  def calculateReactionHeat(self):
    self.cdata.calculateReactionHeat()

  def classifySpeciesByPhase(self):
    self.cdata.classifySpeciesByPhase()

  def get_aux_info(self):
    return {
      't_calc': self.cdata.auxdata.t_calc,
      'k_eva_tot': self.cdata.auxdata.k_eva_tot,
      'k_ads_tot': self.cdata.auxdata.k_ads_tot,
      'mant_tot': self.cdata.auxdata.mant_tot,
      'surf_tot': self.cdata.auxdata.surf_tot,
      'n_surf2mant': self.cdata.auxdata.n_surf2mant,
      'n_mant2surf': self.cdata.auxdata.n_mant2surf
    }

  cdef _get_ads_reactions(self):
    return [{'reactants': _.sReactants,
             'products': _.sProducts,
             'abc': _.abc,
             'Trange': _.Trange,
             'itype': _.itype}
            for _ in self.cdata.auxdata.ads_reactions]

  def get_ads_reactions(self):
    return self._get_ads_reactions()

  cdef _get_eva_reactions(self):
    return [{'reactants': _.sReactants,
             'products': _.sProducts,
             'abc': _.abc,
             'Trange': _.Trange,
             'itype': _.itype}
            for _ in self.cdata.auxdata.eva_reactions]

  def get_eva_reactions(self):
    return self._get_eva_reactions()

  cdef _get_all_reactions(self):
    return [{'reactants': _.sReactants,
             'products': _.sProducts,
             'abc': _.abc,
             'Trange': _.Trange,
             'itype': _.itype,
             'drdy': _.drdy,
             'rate': _.rate,
             'heat': _.heat
            }
            for _ in self.cdata.reactions]

  def get_all_reactions(self):
    self.all_reactions = self._get_all_reactions()
    return self.all_reactions

  @property
  def reactions(self):
    if self.all_reactions is not None:
      return self.all_reactions
    self.all_reactions = self._get_all_reactions()
    return self.all_reactions

  @property
  def reaction_types(self):
    return self.cdata.reaction_types

  @property
  def physical_params(self):
    return self.get_all_phy_params()

  @property
  def name2idx(self):
    return self.cdata.species.name2idx

  @property
  def idx2name(self):
    return self.cdata.species.idx2name

  @property
  def elementsSpecies(self):
    return self.cdata.species.elementsSpecies

  @property
  def massSpecies(self):
    return self.cdata.species.massSpecies

  @property
  def enthalpies(self):
    return self.cdata.species.enthalpies

  @property
  def vibFreqs(self):
    return self.cdata.species.vibFreqs

  @property
  def diffBarriers(self):
    return self.cdata.species.diffBarriers

  @property
  def quantMobilities(self):
    return self.cdata.species.quantMobilities

  @property
  def gasSpecies(self):
    return self.cdata.species.gasSpecies

  @property
  def surfaceSpecies(self):
    return self.cdata.species.surfaceSpecies

  @property
  def mantleSpecies(self):
    return self.cdata.species.mantleSpecies

  @property
  def abundances(self):
    return self.cdata.species.abundances

  @property
  def duplicate_reactions(self):
    return self.cdata.dupli

  def load_reactions(self, fname, nReactants=3, nProducts=4, nABC=3,
    lenSpeciesName=12, lenABC=9, nT=2, lenT=6, lenType=3, rowlen_min=126):
    load_reactions(fname, self.cdata, nReactants, nProducts,
    nABC, lenSpeciesName, lenABC, nT, lenT, lenType, rowlen_min)

  def loadInitialAbundances(self, fname):
    loadInitialAbundances(self.cdata.species, fname)

  def loadSpeciesEnthalpies(self, fname):
    loadSpeciesEnthalpies(self.cdata.species, fname)

  def assignReactionHandlers(self):
    assignReactionHandlers(self.cdata)

  def setAbundanceByName(self, name, val):
    if len(self.cdata.species.abundances) == 0:
      self.cdata.species.allocate_abundances()
    idx = self.cdata.species.name2idx[name]
    self.cdata.species.abundances[idx] = val

  def setAbundanceByDict(self, a):
    if len(self.cdata.species.abundances) == 0:
      self.cdata.species.allocate_abundances()
    for k in a:
      idx = self.cdata.species.name2idx[k]
      self.cdata.species.abundances[idx] = a[k]

  def setAbundances(self, vals):
    if len(self.cdata.species.abundances) == 0:
      self.cdata.species.allocate_abundances()
    for i in range(len(self.cdata.species.idx2name)):
      self.cdata.species.abundances[i] = vals[i]

  def assignElementsToOneSpecies(self, name, elements):
    return assignElementsToOneSpecies(name, elements)

  def __init__(self, fReactions=None, fInitialAbundances=None,
               fSpeciesEnthalpies=None):
    """
  __init__(self, fReactions=None, fInitialAbundances=None,
           fSpeciesEnthalpies=None)
    """
    self.all_reactions = None

    if fReactions is not None:
      self.load_reactions(fReactions)
    if fInitialAbundances is not None:
      self.loadInitialAbundances(fInitialAbundances)
    if fSpeciesEnthalpies is not None:
      self.loadSpeciesEnthalpies(fSpeciesEnthalpies)

  def prepare(self):
    self.assort_reactions()
    self.assignElementsToSpecies()
    self.calculateSpeciesMasses()
    self.calculateSpeciesVibFreqs()
    self.calculateSpeciesDiffBarriers()
    self.calculateSpeciesQuantumMobilities()
    self.calculateReactionHeat()
    self.classifySpeciesByPhase()
    self.assignReactionHandlers()


def simpleInterpol(ts, vs, t):
    """simpleInterpol(ts, vs, t)
    ts: t values
    vs: values
    t: t value to be interpolated"""
    return interpol(ts, vs, t)

def rate_Arrhenius(T, abc, iS=0):
    return arrhenius(T, abc, iS)


def run_one_model(p, model=None):
    t_start = datetime.datetime.now()

    model.prepare()
    model.set_solver(solver_id=p['model_id'])

    if p.get('y0'):
        init_y = p['y0']
    else:
        init_y = model.abundances

    s = {'ts': [], 'ys': [], 'phy_s': [], 'finished': False,
         'y': [_ for _ in init_y],
         't': p.get('t0') or 0.0, 'dt': p['dt0']}

    model.set_phy_params_by_dict(p['phy_params'])

    for i in range(p['nmax']):
        s['t'], s['y'] = model.update(s['y'], t=s['t'], dt=s['dt'])
        s['phy_s'].append(model.get_all_phy_params())
        s['ts'].append(s['t'])
        s['ys'].append(s['y'])
        if s['t'] >= p['t_max_s']:
            s['finished'] = True
            break
        s['dt'] *= p['t_ratio']
        if s['t'] + s['dt'] > p['t_max_s']:
            s['dt'] = p['t_max_s'] - s['t']
    print('Solver:', p['model_id'], 'finished:',
          (datetime.datetime.now() - t_start).total_seconds(), 'seconds elapsed')
    return s


def get_total_charge(ab_s, model):
    s = 0.0
    for i in range(len(ab_s)):
        s += ab_s[i] * (model.elementsSpecies[i][b'+']
                      - model.elementsSpecies[i][b'-'])
    return s


def get_phy_params_default():
  return {
    b'Av': 20.0,
    b'G0_UV': 1.0,
    b'Ncol_H2': 4e22,
    b'T_dust': 15.0,
    b'T_gas': 15.0,
    b'chemdesorption_factor': 0.05,
    b'chi_Xray': 0.0,
    b'chi_cosmicray': 1.0,
    b'dust2gas_mass': 1e-2,
    b'dust_albedo': 0.6,
    b'dust_material_density': 2.0,
    b'dust_radius': 0.1e-4,
    b'dust_site_density': 1e15,
    b'dv_km_s': 1.0,
    b'v_km_s': 14.5,
    b'mean_mol_weight': 1.4,
    b'n_gas': 5e4,
    b't_max_year': 1e7}


def hasElement(s, name, ele):
    return s.assignElementsToOneSpecies(name, cs.element_masses)[ele]


def N_H_to_Av(N_H, ratio=5.3e-22):
    # Draine, equation 21.7
    return N_H * ratio


def Av_to_N_H(Av, ratio=5.3e-22):
    # Draine, equation 21.7
    return Av / ratio


def N_H_to_ngas(N_H, thickness_pc=None):
    pc = 3.1e18 # cm
    return N_H / (thickness_pc * pc)


def Td_from_Av(Av, G0=1):
    # Tielens Book, 9.18
    T0 = 12.2 * np.power(G0, 0.25)
    tau100 = 1e-3
    nu0 = 3e15
    return np.power(8.9e-11 * nu0 * G0 * np.exp(-1.8*Av) +
                    2.78**5 + 3.4e-2 * (0.42 - np.log(3.5e-2 * tau100 * T0)
                                               * tau100 * T0**6),
                    0.2)

def chem2tex(s):
    return re.sub('([+-]+)', r'$^{\1}$',
                  re.sub('(\d+)', r'$_{\1}$', s))


def printFormationDestruction(sp, md, res, tmin=None, tmax=None, nstep=10,
                              showFirst=10, showFraction=0.1):
    """def printFormationDestruction(sp, md, res, tmin=None, tmax=None, nstep=10,
                              showFirst=10, showFraction=0.1):
    """
    iSpe = md.name2idx[sp]
    for n in range(0, len(res['ts']), nstep):
        t = res['ts'][n] / cs.phy_SecondsPerYear
        if not (tmin <= t <= tmax):
            continue
        frr = md.getFormationReactionsWithRates(iSpe, res['ts'][n], res['ys'][n])
        drr = md.getDestructionReactionsWithRates(iSpe, res['ts'][n], res['ys'][n])
        Tg, Td, ng = md.get_phy_param(b'T_gas'), md.get_phy_param(b'T_dust'), md.get_phy_param(b'n_gas')
        ftt = np.sum([_[1] for _ in frr])
        dtt = np.sum([_[1] for _ in drr])
        ftscale = res['ys'][n][iSpe] / ftt / cs.phy_SecondsPerYear
        dtscale = res['ys'][n][iSpe] / dtt / cs.phy_SecondsPerYear
        frmax = frr[0][1]
        drmax = drr[0][1]
        print('{:.3e}, {:.3e}, {:.3e}, {:.3e}, {:.2f}, {:.2f}, {:.2e}, {:.2e}, {:.2e}, {:.2e}, {:d}'.format(
            t, ftt, dtt, (ftt-dtt)/(ftt+dtt), Tg, Td, ng, ftscale, dtscale, res['ys'][n][iSpe], n))
        for ifr,fr in frr[:showFirst]:
            if fr < frmax * showFraction:
                break
            reac = md.reactions[ifr]
            print(f'{fr:.3e}',
                  ' + '.join([_.decode() for _ in reac['reactants']]), ' -> ',
                  ' + '.join([_.decode() for _ in reac['products']]), reac['abc'], ifr)
        for idr,dr in drr[:showFirst]:
            if dr < drmax * showFraction:
                break
            reac = md.reactions[idr]
            print(f'{-dr:.3e}',
                  ' + '.join([_.decode() for _ in reac['reactants']]), ' -> ',
                  ' + '.join([_.decode() for _ in reac['products']]), reac['abc'], idr)
    return
