# cython: embedsignature=True, cdivision=True

################################################################################
#
#   RMG - Reaction Mechanism Generator
#
#   Copyright (c) 2002-2009 Prof. William H. Green (whgreen@mit.edu) and the
#   RMG Team (rmg_dev@mit.edu)
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#
################################################################################

"""
This module contains classes and functions for working with collision models.
"""

import numpy

cimport rmgpy.constants as constants
import rmgpy.quantity as quantity
from libc.math cimport exp, sqrt

################################################################################

def CollisionError(Exception):
    pass

################################################################################

cdef class LennardJones:
    """
    A set of Lennard-Jones collision parameters. The attributes are:

    =================== ========================================================
    Attribute           Description
    =================== ========================================================
    `sigma`             Distance at which the inter-particle potential is minimum
    `epsilon`           Depth of the potential well
    =================== ========================================================
    
    """

    def __init__(self, sigma=None, epsilon=None):
        self.sigma = sigma
        self.epsilon = epsilon

    def __repr__(self):
        """
        Return a string representation that can be used to reconstruct the
        object.
        """
        return 'LennardJones(sigma={0!r}, epsilon={1!r})'.format(self.sigma, self.epsilon)

    def __reduce__(self):
        """
        A helper function used when pickling an object.
        """
        return (LennardJones, (self.sigma, self.epsilon))
    
    property sigma:
        """The distance at which the inter-particle potential is minimum."""
        def __get__(self):
            return self._sigma
        def __set__(self, value):
            self._sigma = quantity.Length(value)

    property epsilon:
        """The depth of the potential well."""
        def __get__(self):
            return self._epsilon
        def __set__(self, value):
            try:
                self._epsilon = quantity.Temperature(value)
                self._epsilon.value_si *= constants.R
                self._epsilon.units = 'kJ/mol'
            except quantity.QuantityError:
                self._epsilon = quantity.Energy(value)

    cpdef double getCollisionFrequency(self, double T, double M, double mu) except -1:
        """
        Return the value of the Lennard-Jones collision frequency in Hz at the
        given temperature `T` in K for colliders with the given concentration
        `M` in mol/m^3 and reduced mass `mu` in amu.
        """
        cdef double sigma, epsilon
        cdef double Tred, omega22
        sigma = self._sigma.value_si
        epsilon = self._epsilon.value_si
        M *= constants.Na       # mol/m^3 -> molecules/m^3
        Tred = constants.R * T / epsilon
        omega22 = 1.16145 * Tred**(-0.14874) + 0.52487 * exp(-0.77320 * Tred) + 2.16178 * exp(-2.43787 * Tred)
        mu *= constants.amu
        return omega22 * sqrt(8 * constants.kB * T / constants.pi / mu) * constants.pi * sigma * sigma * M

################################################################################

cdef class SingleExponentialDown:
    """
    A representation of a single exponential down model of collisional energy
    transfer. The attributes are:
    
    =================== ========================================================
    Attribute           Description
    =================== ========================================================
    `alpha0`            The average energy transferred in a deactivating collision at the reference temperature
    `T0`                The reference temperature
    `n`                 The temperature exponent
    =================== ========================================================
    
    """

    def __init__(self, alpha0=None, T0=None, n=0.0):
        self.alpha0 = alpha0
        self.T0 = T0
        self.n = n

    def __repr__(self):
        """
        Return a string representation that can be used to reconstruct the
        object.
        """
        return 'SingleExponentialDown(alpha0={0!r}, T0={1!r}, n={2:g})'.format(self.alpha0, self.T0, self.n)

    def __reduce__(self):
        """
        A helper function used when pickling an object.
        """
        return (SingleExponentialDown, (self.alpha0, self.T0, self.n))

    property alpha0:
        """The average energy transferred in a deactivating collision at the reference temperature."""
        def __get__(self):
            return self._alpha0
        def __set__(self, value):
            try:
                self._alpha0 = quantity.Frequency(value)
                self._alpha0.value_si *= constants.h * constants.c * 100. * constants.Na
                self._alpha0.units = 'kJ/mol'
            except quantity.QuantityError:
                self._alpha0 = quantity.Energy(value)

            self._alpha0 = quantity.Energy(value)

    property T0:
        """The reference temperature."""
        def __get__(self):
            return self._T0
        def __set__(self, value):
            self._T0 = quantity.Temperature(value)

    cpdef double getAlpha(self, double T) except -1000000000:
        """
        Return the value of the :math:`\\alpha` parameter - the average energy
        transferred in a deactivating collision - in J/mol at temperature `T`
        in K.
        """
        cdef double alpha0, T0
        alpha0 = self._alpha0.value_si
        if self._T0 is None:
            return alpha0
        else:
            T0 = self._T0.value_si
            return alpha0 * (T / T0) ** self.n

    def generateCollisionMatrix(self,
        double T,
        numpy.ndarray[numpy.float64_t,ndim=2] densStates,
        numpy.ndarray[numpy.float64_t,ndim=1] Elist,
        numpy.ndarray[numpy.int_t,ndim=1] Jlist=None):
        """
        Generate and return the collision matrix
        :math:`\\matrix{M}_\\mathrm{coll} / \\omega = \\matrix{P} - \\matrix{I}`
        corresponding to this collision model for a given set of energies
        `Elist` in J/mol, temperature `T` in K, and isomer density of states
        `densStates`.
        """

        cdef double alpha, beta
        cdef double C, left, right
        cdef int Ngrains, start, i, r, s
        cdef numpy.ndarray[numpy.float64_t,ndim=1] rho
        cdef numpy.ndarray[numpy.float64_t,ndim=2] phi
        cdef numpy.ndarray[numpy.float64_t,ndim=4] P

        Ngrains = Elist.shape[0]
        NJ = Jlist.shape[0] if Jlist is not None else 1
        P = numpy.zeros((Ngrains,NJ,Ngrains,NJ), numpy.float64)

        alpha = 1.0 / self.getAlpha(T)
        beta = 1.0 / (constants.R * T)
        
        rho = numpy.zeros(Ngrains)
        for r in range(Ngrains):
            rho[r] = numpy.sum((2*Jlist+1) * densStates[r,:])
        
        for start in range(Ngrains):
            if rho[start] > 0:
                break

        # Determine unnormalized entries in collisional transfer probability matrix
        for r in range(start, Ngrains):
            for s in range(start,r+1):
                P[s,0,r,0] = exp(-(Elist[r] - Elist[s]) * alpha)
            for s in range(r+1,Ngrains):
                P[s,0,r,0] = exp(-(Elist[s] - Elist[r]) * alpha) * rho[s] / rho[r] * exp(-(Elist[s] - Elist[r]) * beta)
        
        # Normalize using detailed balance
        # This method is much more robust, and corresponds to:
        #    [ 1 1 1 1 ...]
        #    [ 1 2 2 2 ...]
        #    [ 1 2 3 3 ...]
        #    [ 1 2 3 4 ...]
        for r in range(start, Ngrains):
            left = 0.0; right = 0.0
            for s in range(start, r): left += P[s,0,r,0]
            for s in range(r, Ngrains): right += P[s,0,r,0]
            C = (1 - left) / right
            # Check for normalization consistency (i.e. all numbers are positive)
            if C < 0: raise CollisionError('Encountered negative normalization coefficient while normalizing collisional transfer probabilities matrix.')
            for s in range(r+1,Ngrains):
                P[r,0,s,0] *= C
                P[s,0,r,0] *= C
            P[r,0,r,0] = P[r,0,r,0] * C - 1
        # This method is described by Pilling and Holbrook, and corresponds to:
        #    [ ... 4 3 2 1 ]
        #    [ ... 3 3 2 1 ]
        #    [ ... 2 2 2 1 ]
        #    [ ... 1 1 1 1 ]
        #for r in range(Ngrains, start, -1):
            #left = 0.0; right = 0.0
            #for s in range(start, r): left += P[s,r]
            #for s in range(r, Ngrains): right += P[s,r]
            #C = (1 - right) / left
            ## Check for normalization consistency (i.e. all numbers are positive)
            #if C < 0: raise CollisionError('Encountered negative normalization coefficient while normalizing collisional transfer probabilities matrix.')
            #for s in range(r-1):
                #P[r,s] *= C
                #P[s,r] *= C
            #P[r,r] = P[r,r] * C - 1

        # If solving the 2D master equation, compute P(E,J,E',J') from P(E,E')
        # by assuming that the J distribution after the collision is independent
        # of that before the collision (the strong collision approximation in J)
        if NJ > 1:
            phi = numpy.zeros_like(densStates)
            for s in range(NJ):
                phi[:,s] = (2*Jlist[s]+1) * densStates[:,s]
            for r in range(start, Ngrains):
                phi[r,:] /= rho[r]
            for r in range(Ngrains):
                for s in range(NJ):
                    P[r,s,:,:] *= phi[r,s]
            
        return P

    def calculateCollisionEfficiency(self,
        double T,
        numpy.ndarray[numpy.float64_t,ndim=1] Elist,
        numpy.ndarray[numpy.int_t,ndim=1] Jlist,
        numpy.ndarray[numpy.float64_t,ndim=2] densStates,
        double E0, double Ereac):
        """
        Calculate an efficiency factor for collisions, particularly useful for the
        modified strong collision method. The collisions involve the given 
        `species` with density of states `densStates` corresponding to energies 
        Elist` in J/mol, ground-state energy `E0` in kJ/mol, and first 
        reactive energy `Ereac` in kJ/mol. The collisions occur at temperature `T` 
        in K and are described by the average energy transferred in a deactivating
        collision `dEdown` in kJ/mol. The algorithm here is implemented as
        described by Chang, Bozzelli, and Dean [Chang2000]_.
    
        .. [Chang2000] A. Y. Chang, J. W. Bozzelli, and A. M. Dean.
           *Z. Phys. Chem.* **214**, p. 1533-1568 (2000).
           `doi: 10.1524/zpch.2000.214.11.1533 <http://dx.doi.org/10.1524/zpch.2000.214.11.1533>`_
    
        """
    
        cdef double dEdown, dE, FeNum, FeDen, Delta1, Delta2, DeltaN, Delta, value, beta
        cdef double R = constants.R
        cdef int Ngrains, NJ, r
    
        # Ensure that the barrier height is sufficiently above the ground state
        # Otherwise invalid efficiencies are observed
        if Ereac - E0 < 100:
            Ereac = E0 + 100
    
        dEdown = self.getAlpha(T)
    
        Ngrains = len(Elist)
        NJ = 1 if Jlist is None else len(Jlist)
        dE = Elist[1] - Elist[0]
        
        FeNum = 0; FeDen = 0
        Delta1 = 0; Delta2 = 0; DeltaN = 0; Delta = 1
    
        for r in range(Ngrains):
            value = 0.0
            for s in range(NJ):
                value += densStates[r,s] * (2*Jlist[s]+1) * exp(-Elist[r] / (R * T))
            if Elist[r] > Ereac:
                FeNum += value
                if FeDen == 0:
                    FeDen = value * R * T / dE
        if FeDen == 0: return 1.0
        Fe = FeNum / FeDen
    
        # Chang, Bozzelli, and Dean recommend "freezing out" Fe at values greater
        # than 1e6 to avoid issues of roundoff error
        # They claim that the collision efficiency isn't too temperature-dependent
        # in this regime, so it's an okay approximation to use
        if Fe > 1e6: Fe = 1e6
        
        for r in range(Ngrains):
            value = 0.0
            for s in range(NJ):
                value += densStates[r,s] * (2*Jlist[s]+1) * exp(-Elist[r] / (R * T))
            # Delta
            if Elist[r] < Ereac:
                Delta1 += value
                Delta2 += value * exp(-(Ereac - Elist[r]) / (Fe * R * T))
            DeltaN += value
    
        Delta1 /= DeltaN
        Delta2 /= DeltaN
    
        Delta = Delta1 - (Fe * R * T) / (dEdown + Fe * R * T) * Delta2
    
        beta = (dEdown / (dEdown + Fe * R * T))**2 / Delta
    
        if beta > 1:
            print('Warning: Collision efficiency {0:.3f} calculated at {1:g} K is greater than unity, so it will be set to unity.'.format(beta, T))
            beta = 1
        if beta < 0:
            raise CollisionError('Invalid collision efficiency {0:.3f} calculated at {1:g} K.'.format(beta, T))
        
        return beta