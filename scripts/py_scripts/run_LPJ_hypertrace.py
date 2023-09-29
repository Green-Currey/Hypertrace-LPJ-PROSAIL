import sys
import os
from LPJ_hypertrace_loop import LPJ_hypertrace_routine

LPJ_hypertrace_routine(
    surface_json = os.getenv("surfacePath"),
    config_json = os.getenv("configPath"),
    reflectance_file = os.getenv("reflectancePath"),
    output_dir = os.getenv("ncdfDir"),
    month = sys.argv[1], 
    mode = os.getenv("hypertraceOrRadiance")
)
