#!/usr/bin/env python3

# inputs are a samples_per_symbol parameter and a message string
# composed of {-1,1} symbols. 

# output is an array of complex samples.

from math import *
import numpy as np

# Parameters and utility functions

bt = 0.3
sigma = sqrt(np.log(2) / (4 * np.pi * np.pi * (bt*bt)))
bigT = 1


def qfun(x):
    return (0.5 * erfc(x/(sqrt(2))))

def frequency_shaping_pulse(x):
    scale = 1/(2*bigT)
    firstQ  = qfun((x/bigT - 0.5)/sigma)
    secondQ = qfun((x/bigT + 0.5)/sigma)
    return (scale * (firstQ - secondQ))


def bigPhi(x):
    return (1.0 - qfun(x))

def bigG(x):
    first_half  = x * bigPhi(x/sigma)
    second_half = (sigma / sqrt(2*np.pi)) * np.exp(-(x*x)/(2*sigma*sigma))
    return first_half+second_half

def phase_shaping_pulse(x):
    foo = bigG((x / bigT) + 0.5) - bigG((x / bigT) - 0.5)
    return 0.5 * foo

def add_pulse(victim, idx, val, pulse):
    victim[idx:idx+pulse.shape[0] ] += val * pulse;
    victim[    idx+pulse.shape[0]:] += val * np.ones_like(victim[idx+pulse.shape[0]:])*0.5
    return victim

def gmsk_modulator_warmup(samples_per_symbol):
    pulserange = np.linspace(-4,4,num=8*samples_per_symbol)
    stored_pulse = np.vectorize(phase_shaping_pulse)(pulserange)
    return stored_pulse

def gmsk_modulate(syms, samples_per_symbol, stored_pulse):
    phase_trajectory = np.zeros((len(syms)+8)*samples_per_symbol, dtype=float)
    for pos,val in enumerate(syms):
        phase_trajectory = add_pulse(phase_trajectory, pos * samples_per_symbol, val, stored_pulse)

    isam = np.cos((np.pi) * phase_trajectory)
    qsam = np.sin((np.pi) * phase_trajectory)
    signal = isam + 1j*qsam
    return signal
