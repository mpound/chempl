from libcpp.string cimport string
from libcpp.map cimport map as cppmap

cdef extern from "constants.hpp" namespace "CONST":
  cppmap[string, double] element_masses
  double PI, PI_div_2, PI_mul_2, SQRT2PI, LN10, phy_elementaryCharge_SI, phy_electronClassicalRadius_SI, phy_electronClassicalRadius_CGS, phy_CoulombConst_SI, phy_atomicMassUnit_SI, phy_mProton_SI, phy_mProton_CGS, phy_mElectron_SI, phy_mElectron_CGS, phy_kBoltzmann_SI, phy_kBoltzmann_CGS, phy_hPlanck_SI, phy_hPlanck_CGS, phy_hbarPlanck_SI, phy_hbarPlanck_CGS, phy_GravitationConst_SI, phy_GravitationConst_CGS, phy_SpeedOfLight_SI, phy_SpeedOfLight_CGS, phy_StefanBoltzmann_SI, phy_StefanBoltzmann_CGS, phy_IdealGasConst_SI, phy_ThomsonScatterCross_CGS, phy_Lsun_SI, phy_Lsun_CGS, phy_Msun_SI, phy_Msun_CGS, phy_Rsun_SI, phy_Rsun_CGS, phy_Rearth_CGS, phy_Mearth_CGS, phy_Rmoon_CGS, phy_Mmoon_CGS, phy_RJupiter_CGS, phy_MJupiter_CGS, phy_SecondsPerYear, phy_Deg2Rad, phy_erg2joule, phy_m2cm, phy_kg2g, phy_eV2erg, phy_cm_1_2erg, phy_cm_1_2K, phy_AvogadroConst, phy_AU2cm, phy_AU2m, phy_pc2m, phy_pc2cm, phy_Angstrom2micron, phy_Angstrom2cm, phy_micron2cm, phy_jansky2CGS, phy_jansky2SI, phy_CMB_T, phy_ratioDust2GasMass_ISM, phy_Habing_photon_energy_CGS, phy_LyAlpha_energy_CGS, phy_UV_cont_energy_CGS, phy_Habing_energy_density_CGS, phy_Habing_photon_flux_CGS, phy_Habing_energy_flux_CGS, phy_UVext2Av, phy_LyAlpha_nu0, phy_LyAlpha_l0, phy_LyAlpha_dnul, phy_LyAlpha_f12, phy_LyAlpha_cross_H2O, phy_LyAlpha_cross_OH, phy_cosmicray_ionization_rate, phy_cosmicray_desorption_factor, phy_cosmicray_desorption_T, phy_cosmicray_attenuate_N_CGS, phy_cosmicray_attenuate_m_CGS, phy_PAH_abundance_0, phy_SitesDensity_CGS, phy_DiffBarrierWidth_CGS, phy_Diff2DesorRatio, phy_DiffBarrierDefault, phy_vibFreqDefault, colDen2Av_coeff, phy_colDen2Av_coeff, phy_colDen2AUV_1000A
