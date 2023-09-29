import sys
from LPJ_hypertest import LPJ_hypertrace_routine

LPJ_hypertrace_routine(
    surface_json = '/discover/nobackup/bcurrey/hypertrace_sims/surface/LPJ_basic_surface.json',
    config_json = '/discover/nobackup/bcurrey/hypertrace_sims/configs/LPJ_basic_surface.json',
    reflectance_file = '/discover/nobackup/projects/SBG-DO/lpj-prosail/version2/lpj-prosail_levelC_HDR_version2a_m_2021.nc',
    month = sys.argv[1], 
    mode = 'hypertrace'
)
