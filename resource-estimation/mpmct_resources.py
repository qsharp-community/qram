# Resources for an MPMCT with n controls
def mpmct_depth(n):
    return 28*n - 60

def mpmct_t_c(n):
    return 12*n - 20

def mpmct_t_d(n):
    return 4*(n-2)

def mpmct_h_c(n):
    return 4*n - 6

def mpmct_cnot_c(n):
    return 24*n - 40
