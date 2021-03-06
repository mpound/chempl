#ifndef CALC_RATE_H
#define CALC_RATE_H

#include "math.h"
#include "types.hpp"
#include "constants.hpp"


namespace CALC_RATE {


inline TYPES::DTP_FLOAT thermal_velocity_CGS(
    const TYPES::DTP_FLOAT T_CGS,
    const TYPES::DTP_FLOAT massnum);


TYPES::DTP_FLOAT rate_adsorption(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_desorption(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rateArrhenius(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_cosmicray_ionization(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_cosmicray_induced_ionization(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_photoionization(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_photodissociation_H2(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


inline TYPES::DTP_FLOAT calc_cross_surf_barrier_prob(
    const TYPES::PhyParams& p, TYPES::Reaction& r);


TYPES::DTP_FLOAT rate_surface_AA(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_surface_AB(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_surface_AA_desorption(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_surface_AB_desorption(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_surf2mant(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


void update_surfmant(
    const TYPES::DTP_FLOAT& t,
    double *y,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_mant2surf(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_iongrain(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_photodesorption(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_CO_photodissociation(
    const TYPES::DTP_FLOAT& t,
    double *y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_CO_photodissociation_better(
    const TYPES::DTP_FLOAT& t,
    double *y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


TYPES::DTP_FLOAT rate_dummy(
    const TYPES::DTP_FLOAT& t,
    const TYPES::DTP_Y y,
    TYPES::Reaction& r,
    const TYPES::PhyParams& p,
    const TYPES::Species& s,
    TYPES::AuxData& m);


void assignAReactionHandler(TYPES::RateCalculators& rcs,
                            const TYPES::RateCalculator& rc,
                            const int& itype);
void assignReactionHandlers(TYPES::Chem_data& user_data);

double arrhenius(const double &T,
    const std::vector<double> &abc, const int &iS);

inline double interval(const double t, const double t0, const double t1,
    const double width0=0.1, const double width1=0.1,
    const double expOverflow=50.0);
}

#endif //CALC_RATE_H
