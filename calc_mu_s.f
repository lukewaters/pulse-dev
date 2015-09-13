!vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvC
!                                                                      C
!  Module name: CALC_MU_s(M, IER)                                      C
!  Purpose: Calculate granular stress terms: THETA, P_s, LAMBDA_s, MU_sC
!                                                                      C
!  Author: W. Rogers                                  Date: 04-mar-92  C
!  Reviewer: M. Syamlal                               Date: 16-MAR-92  C
!                                                                      C
!  Revision Number: 1                                                  C
!  Purpose: Modifications for cylindrical geometry                     C
!  Author: M. Syamlal                                 Date: 15-MAY-92  C
!  Revision Number: 2                                                  C
!  Purpose: Add volume-weighted averaging statement functions for      C
!           variable grid capability                                   C
!  Author:  W. Rogers                                 Date: 21-JUL-92  C
!  Reviewer: P. Nicoletti                             Date: 11-DEC-92  C
!  Revision Number: 3                                                  C
!  Purpose: Add plastic-flow stress terms                              C
!  Author: M. Syamlal                                 Date: 10-FEB-93  C
!  Revision Number: 4                                                  C
!  Purpose: Add Boyle-Massoudi stress terms                            C
!  Author: M. Syamlal                                 Date: 2-NOV-95   C
!  Revision Number: 5                                                  C
!  Purpose: MFIX 2.0 mods  (old name CALC_THETA)                       C
!  Author: M. Syamlal                                 Date: 24-APR_96  C
!  Author: Kapil Agrawal, Princeton University        Date: 6-FEB-98   C
!  Revision Number: 6                                                  C
!  Purpose: Add calculation of viscosities and conductivities for use  C
!           with granular temperature PDE. New common block contained  C
!           in 'trace.inc' contains trD_s_C(DIMENSION_3, DIMENSION_M)  C
!           and trD_s2(DIMENSION_3, DIMENSION_M)                       C
!  Author: Anuj Srivastava, Princeton University      Date: 20-APR-98  C
!  Revision Number:7                                                   C
!  Purpose: Add calculation of frictional stress terms                 C
!                                                                      C
!  Author: Sofiane Benyahia, Fluent Inc.      Date: 02-01-05           C
!  Revision Number:8                                                   C
!  Purpose: Add Simonin and Ahmadi models                              C
!                                                                      C
!  Literature/Document References:                                     C
!  1- Simonin, O., 1996. Combustion and turbulence in two-phase flows. C
!     Von Karman institute for fluid dynamics, lecture series 1996-02  C
!  2- Balzer, G., Simonin, O., Boelle, A., and Lavieville, J., 1996.   C
!     A unifying modelling approach for the numerical prediction of    C
!     dilute and dense gas-solid two phase flow. CFB5, 5th int. conf.  C
!     on circulating fluidized beds, Beijing, China.                   C
!  3- Cao, J. and Ahmadi, G., 1995. Gas-particle two-phase turbulent   C
!     flow in a vertical duct. Int. J. Multiphase Flow, vol. 21 No. 6  C
!     pp. 1203-1228.                                                   C
!                                                                      C
!  Variables referenced: U_s, V_s, W_s, IMAX2, JMAX2, KMAX2, DX, DY,   C
!                        DZ, IMJPK, IMJK, IPJMK, IPJK, IJMK, IJKP,     C
!                        IMJKP, IPJKM, IJKM, IJMKP, IJPK, IJPKM, IJMK, C
!                        M,  RO_s, C_e, D_p, Pi, G_0, X                C
!                                                                      C
!  Variables modified: I, J, K, IJK, MU_s, LAMBDA_s, P_s               C
!                                                                      C
!  Local variables: K_1m, K_2m, K_3m, K_4m, D_s, U_s_N, U_s_S, V_s_E,  C
!                   V_s_W, U_s_T, U_s_B, W_s_E, W_s_W, V_s_T, V_s_B,   C
!                   W_s_N, W_s_S, trD_s_C, W_s_C                       C
!                   trD_s2, EP_s2xTHETA, EP_sxSQRTHETA, I1, I2, U_s_C, C
!                                                                      C
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^C
!
      SUBROUTINE CALC_MU_s(M, IER)
!
      USE param 
      USE param1 
      USE parallel 
      USE physprop
      USE drag
      USE run
      USE geometry
      USE fldvar
      USE visc_g
      USE visc_s
      USE trace
      USE turb
      USE indices
      USE constant
      USE toleranc
      Use vshear
      USE compar
      USE sendrecv
      IMPLICIT NONE
!                      Maximum value of solids viscosity in poise
      DOUBLE PRECISION MAX_MU_s
      PARAMETER (MAX_MU_s = 1000.D0)
!
!  Function subroutines
!
      DOUBLE PRECISION G_0
!
!     Local Variables
!
!                      Error index
      INTEGER          IER
!
!                      Constant in equation for mth solids phase pressure
      DOUBLE PRECISION K_1m
!
!                      Constant in equation for mth solids phase bulk viscosity
      DOUBLE PRECISION K_2m
!
!                      Constant in equation for mth solids phase viscosity
      DOUBLE PRECISION K_3m
!
!                      Constant in equation for mth solids phase dissipation
      DOUBLE PRECISION K_4m
!
!                      Strain rate tensor components for mth solids phase
      DOUBLE PRECISION D_s(3,3)
!
!                      U_s at the north face of the THETA cell-(i, j+1/2, k)
      DOUBLE PRECISION U_s_N
!
!                      U_s at the south face of the THETA cell-(i, j-1/2, k)
      DOUBLE PRECISION U_s_S
!
!                      U_s at the top face of the THETA cell-(i, j, k+1/2)
      DOUBLE PRECISION U_s_T
!
!                      U_s at the bottom face of the THETA cell-(i, j, k-1/2)
      DOUBLE PRECISION U_s_B
!
!                      U_s at the center of the THETA cell-(i, j, k)
!                      Calculated for Cylindrical coordinates only.
      DOUBLE PRECISION U_s_C
!
!                      V_s at the east face of the THETA cell-(i+1/2, j, k)
      DOUBLE PRECISION V_s_E
!
!                      V_s at the west face of the THETA cell-(i-1/2, j, k)
      DOUBLE PRECISION V_s_W
!
!                      V_s at the top face of the THETA cell-(i, j, k+1/2)
      DOUBLE PRECISION V_s_T
!
!                      V_s at the bottom face of the THETA cell-(i, j, k-1/2)
      DOUBLE PRECISION V_s_B
!
!                      W_s at the east face of the THETA cell-(i+1/2, j, k)
      DOUBLE PRECISION W_s_E
!
!                      W_s at the west face of the THETA cell-(1-1/2, j, k)
      DOUBLE PRECISION W_s_W
!
!                      W_s at the north face of the THETA cell-(i, j+1/2, k)
      DOUBLE PRECISION W_s_N
!
!                      W_s at the south face of the THETA cell-(i, j-1/2, k)
      DOUBLE PRECISION W_s_S
!
!                      W_s at the center of the THETA cell-(i, j, k).
!                      Calculated for Cylindrical coordinates only.
      DOUBLE PRECISION W_s_C
!
!                      Cell center value of solids and gas velocities 
      DOUBLE PRECISION USCM, UGC, VSCM, VGC, WSCM, WGC 
! 
!                      Magnitude of gas-solids relative velocity 
      DOUBLE PRECISION VREL
!
!                      Value of EP_s * SQRT( THETA )for Mth solids phase
!                      continuum
      DOUBLE PRECISION EP_sxSQRTHETA
!
!                      Value of EP_s * EP_s * THETA for Mth solids phase
!                      continuum
      DOUBLE PRECISION EP_s2xTHETA
!
!                      Local DO-LOOP counters and phase index
      INTEGER          I1, I2, MM
!
!                      Second invariant of the deviator of D_s
      DOUBLE PRECISION I2_devD_s
!
!                      Factor in plastic-flow stress terms
      DOUBLE PRECISION qxP_s
!
!                      Coefficients of quadratic equation
      DOUBLE PRECISION aq, bq, cq
!
!                      Constant in Boyle-Massoudi stress term
      DOUBLE PRECISION K_5m
!
!                      d(EP_sm)/dX
      DOUBLE PRECISION DEP_soDX
!
!                      d(EP_sm)/dY
      DOUBLE PRECISION DEP_soDY
!
!                      d(EP_sm)/XdZ
      DOUBLE PRECISION DEP_soXDZ
!
!                      Solids volume fraction gradient tensor
      DOUBLE PRECISION M_s(3,3)
!
!                      Trace of M_s
      DOUBLE PRECISION trM_s
!
!                      Trace of (D_s)(M_s)
      DOUBLE PRECISION trDM_s
!
!                      Indices
      INTEGER          I, J, K, IJK, IMJK, IPJK, IJMK, IJPK, IJKM, IJKP,&
                       IJKW, IJKE, IJKS, IJKN, IJKB, IJKT,&
                       IM, JM, KM
      INTEGER          IMJPK, IMJMK, IMJKP, IMJKM, IPJKM, IPJMK, IJMKP,&
                       IJMKM, IJPKM
!
!                      Solids phase
      INTEGER          M
!
! start anuj 04/20
!                      Used to compute frictional terms
      DOUBLE PRECISION Chi, Pc, Mu_f, Lambda_f, Pf, Mu_zeta,Phin,PfoPc
      DOUBLE PRECISION ZETA
! end anuj 04/20
!                      Use to compute MU_s(IJK,M) & Kth_S(IJK,M)
      DOUBLE PRECISION Mu, Mu_b, Mu_star, MUs, Kth, Kth_star

      double precision calc_ep_star
!
!                       defining parametrs for Simonin and Ahmadi models
      DOUBLE PRECISION Tau_12_st, Tau_2_c, Tau_2, Zeta_r, Cos_Theta, C_Beta
      DOUBLE PRECISION Sigma_c, Zeta_c, Omega_c, Zeta_c_2, C_mu, X_21, Nu_t
      DOUBLE PRECISION MU_2_T_Kin, Mu_2_Col, Kappa_kin, Kappa_Col
      DOUBLE PRECISION DGA, C_d, Re
!
!                       defining very dilute ep_g to be used with Sundar's model
      DOUBLE PRECISION EP_g_Dilute 
!
!                       Sum of all solids volume fractions
      DOUBLE PRECISION   SUM_EPS_CP, SUM_EpsGo
 
!     SWITCH enables us to turn on/off the modification to the
!     particulate phase viscosity. If we want to simulate gas-particle
!     flow then SWITCH=1 to incorporate the effect of drag on the
!     particle viscosity. If we want to simulate granular flow
!     without the effects of an interstitial gas, SWITCH=0.
!     (Same for conductivity)
 
!  Function subroutines
!
!
!                      dg0/dep
      DOUBLE PRECISION DG_0DNU,SRT
!                  
      
!
!     Include statement functions
!
!
      INCLUDE 's_pr1.inc'
      INCLUDE 'ep_s1.inc'
      INCLUDE 'fun_avg1.inc'
      INCLUDE 'function.inc'
      INCLUDE 'ep_s2.inc'
      INCLUDE 'fun_avg2.inc'
      INCLUDE 's_pr2.inc'
      
      
      IF(MU_s0 /= UNDEFINED) RETURN  ! constant solids viscosity case
     
! loezos
      IF (SHEAR) THEN           
      SRT=(2d0*V_sh/XLENGTH)
!$omp parallel do private(IJK)
       Do IJK= ijkstart3, ijkend3         
          IF (FLUID_AT(IJK)) THEN  	 
	   V_s(ijk,m)=V_s(IJK,m)+VSH(IJK)	
	  END IF
	END DO	
      END IF	
! loezos      
!
!
!

!!$omp  parallel do &
!!$omp& private(IMJPK, I, J, K, IJK,  IMJK, IPJK, IJMK, IJPK, IJKM, &
!!$omp&  IJKP, IJKW, IJKE, IJKS, IJKN, IJKB, IJKT, IM, JM, KM, &
!!$omp&  U_s_N, U_s_S, U_s_T, U_s_B, V_s_E, V_s_W, V_s_T, V_s_B, W_s_N, &
!!$omp&  W_s_S, W_s_E, W_s_W, U_s_C, W_s_C, D_s, I2_devD_s, trD_s_C, &
!!$omp&  qxP_s, trD_s2, K_1m, K_2m, K_3m, K_4m, K_5m, aq, bq, cq, &
!!$omp&  DEP_soDX, DEP_soDY, DEP_soXDZ, M_s, trM_s, trDM_s, I1, I2, &
!!$omp&  KTH_STAR,KTH,CHI,PFOPC,PC,ZETA,MU_ZETA,PF,LAMBDA_F,MU_F,MUS, &
!!$omp&  MU_STAR,MU_B,MU,M,IJPKM,IJMKM,IJMKP,IPJMK,IPJKM,IMJKM,IMJKP,IMJMK, &
!!$omp&  EP_sxSQRTHETA, EP_s2xTHETA )  

C_RATE_SUM=0.0
      DO 200 IJK = ijkstart3, ijkend3       
!

        IF ( FLUID_AT(IJK) ) THEN
 	

!Dufek
!calculate collision rate estimate

IF ((1.0-EP_G(IJK))<0.4) THEN
COLL_RATE(IJK)=144.*((1.0-EP_G(IJK))**2)*sqrt(THETA_M(IJK,1))/((3.14**1.5)*D_P0(1))
ELSE
COLL_RATE(IJK)=0.0
END IF

C_RATE_SUM=C_RATE_SUM+COLL_RATE(IJK)


!
!------------------------------------------------------------------------
!          CALL SET_INDEX1(IJK, I, J, K, IMJK, IPJK, IJMK, IJPK,
!     &                       IJKM, IJKP, IJKW, IJKE, IJKS, IJKN,
!     &                       IJKB, IJKT, IM, JM, KM)
          I = I_OF(IJK)
          J = J_OF(IJK)
          K = K_OF(IJK)
          IM = Im1(I)
          JM = Jm1(J)
          KM = Km1(K)
          IJKW  = WEST_OF(IJK)
          IJKE  = EAST_OF(IJK)
          IJKS  = SOUTH_OF(IJK)
          IJKN  = NORTH_OF(IJK)
          IJKB  = BOTTOM_OF(IJK)
          IJKT  = TOP_OF(IJK)
          IMJK  = IM_OF(IJK)
          IPJK  = IP_OF(IJK)
          IJMK  = JM_OF(IJK)
          IJPK  = JP_OF(IJK)
          IJKM  = KM_OF(IJK)
          IJKP  = KP_OF(IJK)
          IMJPK = IM_OF(IJPK)
          IMJMK = IM_OF(IJMK)
          IMJKP = IM_OF(IJKP)
          IMJKM = IM_OF(IJKM)
          IPJKM = IP_OF(IJKM)
          IPJMK = IP_OF(IJMK)
          IJMKP = JM_OF(IJKP)
          IJMKM = JM_OF(IJKM)
          IJPKM = JP_OF(IJKM)

	

          U_s_N = AVG_Y(                                   &   !i, j+1/2, k
                   AVG_X_E(U_s(IMJK, M), U_s(IJK, M), I),&
                   AVG_X_E(U_s(IMJPK, M), U_s(IJPK, M), I), J&
                 )
          U_s_S = AVG_Y(                                   &   !i, j-1/2, k
                   AVG_X_E(U_s(IMJMK, M), U_s(IJMK, M), I),&
                   AVG_X_E(U_s(IMJK, M), U_s(IJK, M), I), JM&
                 )
          U_s_T = AVG_Z(                                 &     !i, j, k+1/2
                   AVG_X_E(U_s(IMJK, M), U_s(IJK, M), I),&
                   AVG_X_E(U_s(IMJKP, M), U_s(IJKP, M), I), K&
                 )
          U_s_B = AVG_Z(                                 &     !i, j, k-1/2
                   AVG_X_E(U_s(IMJKM, M), U_s(IJKM, M), I),&
                   AVG_X_E(U_s(IMJK, M), U_s(IJK, M), I), KM&
                 )
! start loezos
	IF (SHEAR)  THEN
	
          V_s_E = AVG_X(                                 &     !i+1/2, j, k
                   AVG_Y_N(V_s(IJMK, M), V_s(IJK, M)),&
                   AVG_Y_N((V_s(IPJMK, M)-VSH(IPJMK)+VSH(IJMK)&
		    +SRT*1d0/oDX_E(I)),&
	            (V_s(IPJK, M)-VSH(IPJK)+VSH(IJK)&
		    +SRT*1d0/oDX_E(I))), I&
                 )
          V_s_W = AVG_X(                                 &     !i-1/2, j, k
                   AVG_Y_N((V_s(IMJMK, M)-VSH(IMJMK)+VSH(IJMK)&
		   -SRT*1d0/oDX_E(IM1(I))),&
		 (V_s(IMJK, M)-VSH(IMJK)+VSH(IJK)&
		-SRT*1d0/oDX_E(IM1(I)))),&
                   AVG_Y_N(V_s(IJMK, M), V_s(IJK, M)), IM)

	ELSE
          V_s_E = AVG_X(                                 &     !i+1/2, j, k
                   AVG_Y_N(V_s(IJMK, M), V_s(IJK, M)),&
                   AVG_Y_N(V_s(IPJMK, M), V_s(IPJK, M)), I&
                 )
          V_s_W = AVG_X(                                 &     !i-1/2, j, k
                   AVG_Y_N(V_s(IMJMK, M), V_s(IMJK, M)),&
                   AVG_Y_N(V_s(IJMK, M), V_s(IJK, M)), IM&
                 )
	END IF
! end loezos
          V_s_T = AVG_Z(                                 &     !i, j, k+1/2
                   AVG_Y_N(V_s(IJMK, M), V_s(IJK, M)),&
                   AVG_Y_N(V_s(IJMKP, M), V_s(IJKP, M)), K&
                 )
          V_s_B = AVG_Z(                                 &    !i, j, k-1/2
                   AVG_Y_N(V_s(IJMKM, M), V_s(IJKM, M)),&
                   AVG_Y_N(V_s(IJMK, M), V_s(IJK, M)), KM&
                 )
          W_s_N = AVG_Y(                                 &    !i, j+1/2, k
                   AVG_Z_T(W_s(IJKM, M), W_s(IJK, M)),&
                   AVG_Z_T(W_s(IJPKM, M), W_s(IJPK, M)), J&
                 )
          W_s_S = AVG_Y(                                 &   !i, j-1/2, k
                   AVG_Z_T(W_s(IJMKM, M), W_s(IJMK, M)),&
                   AVG_Z_T(W_s(IJKM, M), W_s(IJK, M)), JM&
                 )
          W_s_E = AVG_X(                                 &   !i+1/2, j, k
                   AVG_Z_T(W_s(IJKM, M), W_s(IJK, M)),&
                   AVG_Z_T(W_s(IPJKM, M), W_s(IPJK, M)), I&
                 )
          W_s_W = AVG_X(                                 &   !i-1/2, j, k
                   AVG_Z_T(W_s(IMJKM, M), W_s(IMJK, M)),&
                   AVG_Z_T(W_s(IJKM, M), W_s(IJK, M)), IM&
                 )
!
          IF(CYLINDRICAL) THEN
            U_s_C = AVG_X_E(U_s(IMJK, M), U_s(IJK, M), I)    !i, j, k
            W_s_C = AVG_Z_T(W_s(IJKM, M), W_s(IJK, M))    !i, j, k
          ELSE
            U_s_C = ZERO
            W_s_C = ZERO
          ENDIF
!
!         Find components of Mth solids phase continuum strain rate
!         tensor, D_s, at center of THETA cell-(i, j, k)
          D_s(1,1) = ( U_s(IJK,M) - U_s(IMJK,M) ) * oDX(I)
          D_s(1,2) = HALF * ( (U_s_N - U_s_S) * oDY(J) +&
                               (V_s_E - V_s_W) * oDX(I) )
          D_s(1,3) = HALF * ( (W_s_E - W_s_W) * oDX(I) +&
                               (U_s_T - U_s_B) * (oX(I)*oDZ(K)) -&
                                W_s_C * oX(I) )
          D_s(2,1) = D_s(1,2)
          D_s(2,2) = ( V_s(IJK,M) - V_s(IJMK,M) ) * oDY(J)
          D_s(2,3) = HALF * ( (V_s_T - V_s_B) * (oX(I)*oDZ(K)) +&
                               (W_s_N - W_s_S) * oDY(J) )
          D_s(3,1) = D_s(1,3)
          D_s(3,2) = D_s(2,3)
          D_s(3,3) = ( W_s(IJK,M) - W_s(IJKM,M) ) * (oX(I)*oDZ(K)) +&
                      U_s_C * oX(I)


!
!         Calculate the trace of D_s
          trD_s_C(IJK,M) = D_s(1,1) + D_s(2,2) + D_s(3,3)

!
!         Calculate trace of the square of D_s
          trD_s2(IJK,M) = 0.D0  !Initialize the totalizer
          DO 20 I1 = 1,3
            DO 10 I2 = 1,3
              trD_s2(IJK,M) = trD_s2(IJK,M) + D_s(I1,I2)*D_s(I1,I2)
   10       CONTINUE
   20     CONTINUE
!
! Start definition of Relative Velocity
!
!         Calculate velocity components at i, j, k
            UGC = AVG_X_E(U_G(IMJK),U_G(IJK),I) 
            VGC = AVG_Y_N(V_G(IJMK),V_G(IJK)) 
            WGC = AVG_Z_T(W_G(IJKM),W_G(IJK)) 
            USCM = AVG_X_E(U_S(IMJK,1),U_S(IJK,1),I) 
            VSCM = AVG_Y_N(V_S(IJMK,1),V_S(IJK,1)) 
            WSCM = AVG_Z_T(W_S(IJKM,1),W_S(IJK,1)) 
!
!         magnitude of gas-solids relative velocity
!
	    VREL = SQRT((UGC - USCM)**2 + &
	                (VGC - VSCM)**2 + &
			(WGC - WSCM)**2)
!
! start anuj 04/20
 
!  GRANULAR_ENERGY
!  .FALSE.
!         EP_g < EP_star   -->    plastic
!         EP_g >= EP_star  -->    viscous (algebraic)
 
!  GRANULAR_ENERGY
!  .TRUE.
!
!        FRICTION
!        .TRUE.
!              EP_s(IJK,M) > EPS_f_min  -->  friction + viscous(pde)
!              EP_s(IJK,M) < EP_f_min   -->  viscous (pde)
 
!        FRICTION
!       .FALSE.
!              EP_g < EP_star  -->  plastic + viscous(pde)
!              EP_g >= EP_star -->  viscous (pde)
 
! end anuj 04/20
 
          Mu_s(IJK,M)     = ZERO
          LAMBDA_s(IJK,M) = ZERO
!
 
! start anuj 4/20 (modified by sof 02/16/2005)
         IF (SCHAEFFER) THEN
! end anuj 4/20
 
!GERA*****************
 	if (MMAX >= 2) EP_star = Calc_ep_star(ijk, ier)
!*********END GERA*************
 
! added closed pack, this has to be consistent with the normal frictional force
! see for example source_v_s.f. Tardos Powder Tech. 92 (1997) 61-74 explains in
! his equation (3) that solids normal and shear frictional stresses have to be 
! treated consistently. --> sof May 24 2005.
!
          IF(EP_g(IJK) .LT. EP_star .AND. CLOSE_PACKED(M)) THEN 
! part copied from source_v_s.f (sof)
	    SUM_EPS_CP=0.0
	    DO MM=1,MMAX
	      IF (CLOSE_PACKED(MM)) SUM_EPS_CP=SUM_EPS_CP+EP_S(IJK,MM)
	    END DO
! end of part copied
!
!             P_star(IJK) = Neg_H(EP_g(IJK))
!
!  Plastic-flow stress tensor
!
!           Calculate the second invariant of the deviator of D_s
            I2_devD_s = ( (D_s(1,1)-D_s(2,2))**2&
                          +(D_s(2,2)-D_s(3,3))**2&
                          +(D_s(3,3)-D_s(1,1))**2 )/6.&
                          + D_s(1,2)**2 + D_s(2,3)**2 + D_s(3,1)**2
!
!-----------------------------------------------------------------------
!            Gray and Stiles (1988)
!            IF(Sin2_Phi .GT. SMALL_NUMBER) THEN
!              qxP_s = SQRT( (4. * Sin2_Phi) * I2_devD_s
!     &                       + trD_s_C(IJK,M) * trD_s_C(IJK,M))
!              MU_s(IJK, M)     = P_star(IJK) * Sin2_Phi
!     &                         / (qxP_s + SMALL_NUMBER)
!              MU_s(IJK, M)     = MIN(MU_s(IJK, M), MAX_MU_s)
!              LAMBDA_s(IJK, M) = P_star(IJK) * F_Phi
!     &                         / (qxP_s + SMALL_NUMBER)
!              LAMBDA_s(IJK, M) = MIN(LAMBDA_s(IJK, M), MAX_MU_s)
!            ELSE
!              MU_s(IJK, M)     = ZERO
!              LAMBDA_s(IJK, M) = ZERO
!            ENDIF
!-----------------------------------------------------------------------
!           Schaeffer (1987)
!
            qxP_s            = SQRT( (4.D0 * Sin2_Phi) * I2_devD_s)
            MU_s(IJK, M)     = P_star(IJK) * Sin2_Phi&
                               / (qxP_s + SMALL_NUMBER) &
			       *(EP_S(IJK,M)/SUM_EPS_CP) ! added by sof for consistency
			                                 ! with solids pressure treatment
            MU_s(IJK, M)     = MIN(MU_s(IJK, M), MAX_MU_s)
 
            LAMBDA_s(IJK, M) = ZERO
            ALPHA_s(IJK, M)  = ZERO
            P_s(IJK, M)  = ZERO
!
! when solving for the granular energy equation (PDE) setting theta = 0 is done 
! in solve_granular_energy.f to avoid convergence problems. (sof)
	    IF(.NOT.GRANULAR_ENERGY) THETA_m(IJK, M) = ZERO
          ENDIF
         ENDIF
!           end Schaeffer
!
! This represents the gas VOF in a fluid cell that contains a single particle
          
	  IF(NO_K) THEN
	    EP_g_Dilute = (1.0d0 - PI*D_p(IJK,M)*D_p(IJK,M)*ODX(I)*ODY(J))
	  ELSE
	    EP_g_Dilute = (1.0d0 - PI/6.0d0*D_p(IJK,M)*D_p(IJK,M)*D_p(IJK,M)*ODX(I) &
	                           *ODY(J)*ODZ(K))
	  ENDIF
!
! Defining a single particle drag coefficient (similar to one defined in drag_gs)
!
	  Re = D_p(IJK,M)*VREL*ROP_G(IJK)/(MU_G(IJK) + small_number)
          IF(Re .LE. 1000D0)THEN
             C_d = (24.D0/(Re+SMALL_NUMBER)) * (ONE + 0.15D0 * Re**0.687D0)
          ELSE
             C_d = 0.44D0
          ENDIF
! This is from Wen-Yu correlation, you can put here your own single particle drag
!	      
	  DgA = 0.75D0 * C_d * VREL * ROP_g(IJK) / D_p(IJK,M)
	  IF(VREL == ZERO) DgA = LARGE_NUMBER !for 1st iteration and 1st time step
!
! Define some time scales and constants related to Simonin and Ahmadi models
!
          IF(SIMONIN .OR. AHMADI) THEN
	    C_mu = 9.0D-02
! particle relaxation time. For very dilute flows avoid singularity by
! redefining the drag as single partilce drag
!
	    IF(Ep_s(IJK,M) > DIL_EP_S .AND. F_GS(IJK,1) > small_number) THEN
	      Tau_12_st = Ep_s(IJK,M)*RO_s(M)/F_GS(IJK,1)
	    ELSE !for dilute flows, drag equals single particle drag law
	      Tau_12_st = RO_s(M)/DgA
	    ENDIF !for dilute flows
	      
	      
! time scale of turbulent eddies
	    Tau_1(ijk) = 3.d0/2.d0*C_MU*K_Turb_G(IJK)/(E_Turb_G(IJK)+small_number)
	  ENDIF
!
! Define some time scales and constants and K_12 related to Simonin model only	  
!
          IF(SIMONIN) THEN
! This is Zeta_r**2 as defined by Simonin
            Zeta_r = 3.0d0 * VREL**2 / (2.0d0*K_Turb_G(IJK)+small_number)
!
! parameters for defining Tau_12: time-scale of the fluid turbulent motion
! viewed by the particles (crossing trajectory effect)
!
            IF(SQRT(USCM**2+VSCM**2+WSCM**2) .GT. zero) THEN
              Cos_Theta = ((UGC-USCM)*USCM+(VGC-VSCM)*VSCM+(WGC-WSCM)*WSCM)/ &
                          (SQRT((UGC-USCM)**2+(VGC-VSCM)**2+(WGC-WSCM)**2)*  &
                           SQRT(USCM**2+VSCM**2+WSCM**2))
            ELSE
	      Cos_Theta = ONE
	    ENDIF

            C_Beta = 1.8d0 - 1.35d0*Cos_Theta**2
!	    
! Lagrangian Integral time scale: Tau_12	    
            Tau_12(ijk) = Tau_1(ijk)/sqrt(ONE+C_Beta*Zeta_r)
!
! Defining the inter-particle collision time
!
	    IF(Ep_s(IJK,M) > DIL_EP_S) THEN
              Tau_2_c = D_p(IJK,M)/(6.d0*Ep_s(IJK,M)*G_0(IJK,M,M) &
                       *DSQRT(16.d0*(Theta_m(ijk,m)+Small_number)/PI))
	    ELSE ! assign it a large number
	      Tau_2_c = LARGE_NUMBER
	    ENDIF
! 
            Sigma_c = (ONE+ C_e)*(3.d0-C_e)/5.d0
!	
! Zeta_c: const. to be used in the K_2 Diffusion coefficient.
            Zeta_c  = (ONE+ C_e)*(49.d0-33.d0*C_e)/100.d0

            Omega_c = 3.d0*(ONE+ C_e)**2 *(2.d0*C_e-ONE)/5.d0

            Zeta_c_2= 2./5.*(ONE+ C_e)*(3.d0*C_e-ONE)

! mixed time scale in the generalized Simonin theory (switch between dilute
! and kinetic theory formulation of the stresses)
            Tau_2 = ONE/(2./Tau_12_st+Sigma_c/Tau_2_c)
!
! The ratio of densities
            X_21 = Ep_s(IJK,M)*RO_s(M)/(EP_g(IJK)*RO_g(IJK))
!
! The ratio of these two time scales.
            Nu_t =  Tau_12(ijk)/Tau_12_st
!
! Definition of an "algebraic" form of of Simonin K_12 PDE. This is obtained
! by equating the dissipation term to the exchange terms in the PDE and 
! neglecting all other terms, i.e. production, convection and diffusion.
! This works because Tau_12 is very small for heavy particles

            K_12(ijk) = Nu_t / (ONE+Nu_t*(ONE+X_21)) * &
                       (2.d+0 *K_Turb_G(IJK) + 3.d+0 *X_21*theta_m(ijk,m))
!  Realizability Criteria         
	    IF(K_12(ijk) > DSQRT(6.0D0*K_Turb_G(IJK)*theta_m(ijk,m))) THEN
	      K_12(ijk) = DSQRT(6.0D0*K_Turb_G(IJK)*theta_m(ijk,m))
	    ENDIF
!
          ENDIF ! for Simonin
!
!
!
!  Viscous-flow stress tensor
!
          IF(.NOT.GRANULAR_ENERGY) THEN  !algebraic granular energy equation
            IF(EP_g(IJK) .GE. EP_star) THEN
!
!
!             Calculate K_1m, K_2m, K_3m, K_4m
              K_1m = 2.D0 * (ONE + C_e) * RO_s(M) * G_0(IJK, M,M)
              K_3m = HALF * D_p(IJK,M) * RO_s(M) * (&
                  ( (SQRT_PI / (3.D0*(3.D0 - C_e))) *&
                  (HALF*(3d0*C_e+ONE) + 0.4D0*(ONE + C_e)*(3.D0*C_e - ONE)*&
                  EP_s(IJK,M)*G_0(IJK, M,M)) ) +&
                  8.D0*EP_s(IJK,M)*G_0(IJK, M,M)*(ONE + C_e) /&
                  (5.D0*SQRT_PI) )
              K_2m = 4.D0 * D_p(IJK,M) * RO_s(M) * (ONE + C_e) *&
                  EP_s(IJK,M) * G_0(IJK, M,M) / (3.D0 * SQRT_PI) -&
                  2.D0/3.D0 * K_3m
              K_4m = 12.D0 * (ONE - C_e*C_e) *&
                  RO_s(M) * G_0(IJK, M,M) / (D_p(IJK,M) * SQRT_PI)
              aq   = K_4m*EP_s(IJK,M)
              bq   = K_1m*EP_s(IJK,M)*trD_s_C(IJK,M)
              cq   = -(K_2m*trD_s_C(IJK,M)*trD_s_C(IJK,M)&
                     + 2.D0*K_3m*trD_s2(IJK,M))
!
!             Boyle-Massoudi Stress term
!
              IF(V_ex .NE. ZERO) THEN
                K_5m = 0.4 * (ONE + C_e) * G_0(IJK, M,M) * RO_s(M) *&
                  ( (V_ex * D_p(IJK,M)) / (ONE - EP_s(IJK,M) * V_ex) )**2
                DEP_soDX  = ( EP_s(IJKE, M) - EP_s(IJK, M) ) * oDX_E(I)&
                 * ( ONE / ( (oDX_E(IM)/oDX_E(I)) + ONE ) ) +&
                 ( EP_s(IJK, M) - EP_s(IJKW, M) ) * oDX_E(IM)&
                 * ( ONE / ( (oDX_E(I)/oDX_E(IM)) + ONE ) )
                DEP_soDY  = ( EP_s(IJKN, M) - EP_s(IJK, M) ) * oDY_N(J)&
                 * ( ONE / ( (oDY_N(JM)/oDY_N(J)) + ONE ) ) +&
                 ( EP_s(IJK, M) - EP_s(IJKS, M) ) * oDY_N(JM)&
                 * ( ONE / ( (oDY_N(J)/oDY_N(JM)) + ONE ) )
                DEP_soXDZ  = (( EP_s(IJKT, M) - EP_s(IJK, M) )&
                 * oX(I)*oDZ_T(K)&
                 * ( ONE / ( (oDZ_T(KM)/oDZ_T(K)) + ONE ) ) +&
                 ( EP_s(IJK, M) - EP_s(IJKB, M) ) * oX(I)*oDZ_T(KM)&
                 * ( ONE / ( (oDZ_T(K)/oDZ_T(KM)) + ONE ) ) ) /&
                 X(I)
                M_s(1,1) = DEP_soDX * DEP_soDX
                M_s(1,2) = DEP_soDX * DEP_soDY
                M_s(1,3) = DEP_soDX * DEP_soXDZ
                M_s(2,1) = DEP_soDX * DEP_soDY
                M_s(2,2) = DEP_soDY * DEP_soDY
                M_s(2,3) = DEP_soDY * DEP_soXDZ
                M_s(3,1) = DEP_soDX * DEP_soXDZ
                M_s(3,2) = DEP_soDY * DEP_soXDZ
                M_s(3,3) = DEP_soXDZ * DEP_soXDZ
                trM_s    = M_s(1,1) + M_s(2,2) + M_s(3,3)
                trDM_s = ZERO
                DO 40 I1 = 1,3
                  DO 30 I2 = 1,3
                    trDM_s = trDM_s + D_s(I1,I2)*M_s(I1,I2)
   30             CONTINUE
   40           CONTINUE
                bq   = bq + EP_s(IJK,M) * K_5m * (trM_s + 2.D0 * trDM_s)
              ELSE
                K_5m = ZERO
              ENDIF
!
!             Calculate EP_sxSQRTHETA and EP_s2xTHETA
              EP_sxSQRTHETA = (-bq + SQRT(bq**2 - 4.D0 * aq * cq ))&
                             / ( 2.D0 * K_4m )
              EP_s2xTHETA = EP_sxSQRTHETA * EP_sxSQRTHETA
 
              IF(EP_s(IJK,M) > SMALL_NUMBER)THEN
!start      kapil&anuj 01/19/98
!               Find pseudo-thermal temperature in the Mth solids phase
                THETA_m(IJK,M) = EP_s2xTHETA/(EP_s(IJK,M)*EP_s(IJK,M))
!end      kapil&anuj 01/19/98
              ELSE
                THETA_m(IJK,M) = ZERO
              ENDIF
!
!             Find pressure in the Mth solids phase
              P_s(IJK,M) = K_1m * EP_s2xTHETA
!
!             bulk viscosity in Mth solids phase
              LAMBDA_s(IJK,M) = K_2m * EP_sxSQRTHETA
!
!             shear viscosity in Mth solids phase
              MU_s(IJK,M) = K_3m * EP_sxSQRTHETA
!
!             Boyle-Massoudi stress coefficient
              ALPHA_s(IJK, M) = -K_5m * EP_s2xTHETA
	    ENDIF
 
          ELSE	!granular energy transport equation
	        ! This is also used whith Simonin or Ahmadi models
!
! This is added for consistency of multi-particles kinetic theory. Solids pressure,
! viscosity and conductivity must be additive. Thus non-linear terms (eps^2) are 
! corrected so the stresses of two identical solids phases are equal to those
! of a single solids phase. sof June 15 2005.
!            
	    SUM_EpsGo = ZERO
            DO MM = 1, MMAX
	      SUM_EpsGo =  SUM_EpsGo+EP_s(IJK,MM)*G_0(IJK,MM,MM)
	    ENDDO 
!
!           Find pressure in the Mth solids phase
            P_s(IJK,M) = ROP_s(IJK,M)*(1d0+ 4.D0 * Eta *&
                           SUM_EpsGo)*Theta_m(IJK,M)
!
! implement Simonin (same as granular) and Ahmadi solids pressures
            IF(SIMONIN) THEN
	      P_s(IJK,M) = P_s(IJK,M) ! no changes to solids pressure
	    ELSE IF(AHMADI) THEN
	      P_s(IJK,M) = ROP_s(IJK,M)*Theta_m(IJK,M) * ( (ONE + 4.0D0* &
	                   SUM_EpsGo ) + HALF*(ONE - C_e*C_e) )
	    ENDIF

! find bulk and shear viscosity
!	    
            Mu = (5d0*DSQRT(Pi*Theta_m(IJK,M))*D_p(IJK,M)*RO_s(M))/96d0
 
            Mu_b = (256d0*Mu*EP_s(IJK,M)*SUM_EpsGo)&
                     /(5d0*Pi)
! added Ro_g = 0 for granular flows (no gas). sof Aug-02-2005 
            IF(SWITCH == ZERO .OR. RO_G(IJK) == ZERO) THEN !sof modifications (May 20 2005)
              Mu_star = Mu
		
	    ELSEIF(Theta_m(IJK,M) .LT. SMALL_NUMBER)THEN
              Mu_star = ZERO
	
            ELSEIF(EP_g(IJK) .GE. EP_g_Dilute) THEN
	      
              
	      Mu_star = RO_S(M)*EP_s(IJK,M)* G_0(IJK,M,M)*Theta_m(IJK,M)* Mu/ &
	               (RO_S(M)*SUM_EpsGo*Theta_m(IJK,M) + &
		       2.0d0*SWITCH*DgA/RO_S(M)* Mu)
	      
	    ELSE
              IF(EP_s(IJK,M) .NE. 0) THEN       ! T Black addition to force no divide by zero, 1/29/2015
              Mu_star = RO_S(M)*EP_s(IJK,M)* G_0(IJK,M,M)*Theta_m(IJK,M)*Mu/ &
	               (RO_S(M)*SUM_EpsGo*Theta_m(IJK,M)+ &
		       (2d0*SWITCH*F_gs(IJK,M)*Mu/(RO_S(M)*EP_s(IJK,M))) )
              ELSE
                  Mu_star = 0
              ENDIF
            ENDIF
!
!           shear viscosity in Mth solids phase  (add to plastic part)
            Mus =&
                   ((2d0+ALPHA)/3d0)*((Mu_star/(Eta*(2d0-Eta)*&
                   G_0(IJK,M,M)))*(ONE+1.6d0*Eta*SUM_EpsGo&
                   )*(ONE+1.6d0*Eta*(3d0*Eta-2d0)*&
                   SUM_EpsGo)+(0.6d0*Mu_b*Eta))
!
! implement Simonin and Ahmadi solids viscosities
            IF(SIMONIN) THEN
!
! Defining Simonin solids turbulent Kinetic (MU_2_T_Kin) and collisional (Mu_2_Col)
! viscosities
	      MU_2_T_Kin = (2.0d0/3.0d0*K_12(ijk)*Nu_t + Theta_m(IJK,M) * &
                          (ONE+ zeta_c_2*EP_s(IJK,M)*G_0(IJK,M,M)))*Tau_2
!
	      Mu_2_Col = 8.d0/5.d0*EP_s(IJK,M)*G_0(IJK,M,M)*Eta* (MU_2_T_Kin+ &
                         D_p(IJK,M)*DSQRT(Theta_m(IJK,M)/PI))
!
              Mu_b = 5.d0/3.d0*EP_s(IJK,M)*RO_s(M)*Mu_2_Col
!
	      Mus = EP_s(IJK,M)*RO_s(M)*(MU_2_T_Kin + Mu_2_Col)
            
	    ELSE IF(AHMADI) THEN
!
! Defining Ahmadi shear and bulk viscosities. Ahmadi coefficient 0.0853 in C_mu
! was replaced by 0.1567 to include 3/2*sqrt(3/2) because K = 3/2 Theta_m
!
	      Mus = ONE/(ONE+ Tau_1(ijk)/Tau_12_st * (ONE-EP_s(IJK,M)/EPS_max)**3)&
	         *0.1045d0*(ONE/G_0(IJK,M,M)+3.2d0*EP_s(IJK,M)+12.1824d0*   &
		 G_0(IJK,M,M)*EP_s(IJK,M)*EP_s(IJK,M))*D_p(IJK,M)*RO_s(M)*  &
		 DSQRT(Theta_m(IJK,M))
!
! This is a guess of what Mu_b might be by taking 5/3 of the collisional viscosity
! contribution. In this case col. visc. is the eps^2 contribution to mus. This
! might be changed later if communications with Ahmadi reveals a diffrent appoach
!
	      Mu_b = 5.d0/3.d0* &
	         ONE/(ONE+ Tau_1(ijk)/Tau_12_st * (ONE-EP_s(IJK,M)/EPS_max)**3)&
	         *0.1045d0*(12.1824d0*G_0(IJK,M,M)*EP_s(IJK,M)*EP_s(IJK,M)) &
		 *D_p(IJK,M)*RO_s(M)* DSQRT(Theta_m(IJK,M))
            
	    ENDIF !for simonin or ahmadi viscosity
 
!
! start anuj 04/20
!           calculate frictional stress
 
            Mu_f = ZERO
            Lambda_f = ZERO
            Pf = ZERO
!
! close_packed was added for concistency with the Schaeffer model
! I'm also extending this model in the case where more than 1 solids
! phase are used. sof May24 2005.
!
            IF (FRICTION .AND. CLOSE_PACKED(M)) THEN
               IF (EP_g(IJK) .LT. (ONE-EPS_f_min)) THEN
!
! part copied from source_v_s.f (sof)
	         SUM_EPS_CP=0.0
	         DO MM=1,MMAX
	           IF (CLOSE_PACKED(MM)) SUM_EPS_CP=SUM_EPS_CP+EP_S(IJK,MM)
	         END DO
! end of part copied
! 
                  IF (SAVAGE.EQ.1) THEN !form of Savage
            	     Mu_zeta =&
                           ((2d0+ALPHA)/3d0)*((Mu/(Eta*(2d0-Eta)*&
                           G_0(IJK,M,M)))*(1d0+1.6d0*Eta*EP_s(IJK,M)*&
                           G_0(IJK,M,M))*(1d0+1.6d0*Eta*(3d0*Eta-2d0)*&
                           EP_s(IJK,M)*G_0(IJK,M,M))+(0.6d0*Mu_b*Eta))
 
 
                     ZETA =&
                            ((48d0*Eta*(1d0-Eta)*RO_s(M)*EP_s(IJK,M)*&
                            EP_s(IJK,M)*G_0(IJK,M,M)*&
                            (Theta_m(IJK,M)**1.5d0))/&
                            (SQRT_Pi*D_p(IJK,M)*2d0*Mu_zeta))**0.5d0
 
                  ELSEIF (SAVAGE.EQ.0) THEN  !S:S form
                     ZETA = (SMALL_NUMBER +&
                             trD_s2(IJK,M) - ((trD_s_C(IJK,M)*&
                             trD_s_C(IJK,M))/3.d0))**0.5d0
 
                  ELSE  !combined form
 
                     ZETA = ((Theta_m(IJK,M)/(D_p(IJK,M)*D_p(IJK,M))) +&
                            (trD_s2(IJK,M) - ((trD_s_C(IJK,M)*&
                             trD_s_C(IJK,M))/3.d0)))**0.5d0
 
                  ENDIF
 
 
                  IF (EP_s(IJK,M) .GT. EPS_max) THEN
                     Pc = 1d25*((EP_s(IJK,M)- EPS_max)**10d0)
                  ELSE
                     Pc = Fr*((EP_s(IJK,M) - EPS_f_min)**N_Pc)/&
                          ((EPS_max - EP_s(IJK,M) + SMALL_NUMBER)&
                           **D_Pc)
                  ENDIF
 
 
                  IF ((trD_s_Co(IJK,M)/(ZETA*N_Pf*DSQRT(2d0)&
                      *Sin_Phi))&
                       .GT. 1d0) THEN
                     Pf =ZERO
                     PfoPc = ZERO
                  ELSE
 
                     Pf = Pc*(1d0 - (trD_s_Co(IJK,M)/(ZETA&
                          *N_Pf*&
                          DSQRT(2d0)*Sin_Phi)))**(N_Pf-1d0)
 
                     PfoPc = (1d0 - (trD_s_Co(IJK,M)/(ZETA&
                          *N_Pf*&
                          DSQRT(2d0)*Sin_Phi)))**(N_Pf-1d0)
                  ENDIF
 
 
 
                  Chi = DSQRT(2d0)*Pf*Sin_Phi*(N_Pf - (N_Pf-1d0)*&
                                      (PfoPc)**(1d0/(N_Pf-1d0)))
 
                  IF (Chi < ZERO) THEN
                     Pf = Pc*((N_Pf/(N_Pf-1d0))**(N_Pf-1d0))
                     Chi = ZERO
                  ENDIF
 
 
                  Mu_f = Chi/(2d0*ZETA)
                  Lambda_f = - 2d0*Mu_f/3d0
!
! modification of the stresses in case of more than one solids phase are used (sof)
!
                  Pf = Pf * (EP_S(IJK,M)/SUM_EPS_CP)
		  Mu_f = Mu_f * (EP_S(IJK,M)/SUM_EPS_CP)
                  Lambda_f = Lambda_f * (EP_S(IJK,M)/SUM_EPS_CP)
 
 
               ENDIF
            ENDIF
 
            Mu_s_c(IJK,M) = MUs
            Mu_s(IJK,M) = Mu_s(IJK,M) + MUs + Mu_f
 
!
!           bulk viscosity in Mth solids phase   (add to plastic part)
 
            LAMBDA_s_c(IJK,M)= Eta*Mu_b - (2d0*MUs/3d0)
            LAMBDA_s(IJK,M) = LAMBDA_s(IJK,M)&
                                + Eta*Mu_b - (2d0*MUs/3d0) + Lambda_f
 
            P_s_c(IJK,M) = P_s(IJK,M)
            P_s(IJK,M) = P_s(IJK,M) + Pf      !add to P_s
! end anuj 04/20
 
            Kth=75d0*RO_s(M)*D_p(IJK,M)*DSQRT(Pi*Theta_m(IJK,M))/&
                  (48d0*Eta*(41d0-33d0*Eta))
 
            IF(SWITCH == ZERO .OR. RO_G(IJK) == ZERO) THEN ! sof modifications (May 20 2005)
              Kth_star=Kth
		
	    ELSEIF(Theta_m(IJK,M) .LT. SMALL_NUMBER)THEN
              Kth_star = ZERO
	
	    ELSEIF(EP_g(IJK) .GE. EP_g_Dilute) THEN
              
	      Kth_star = RO_S(M)*EP_s(IJK,M)* G_0(IJK,M,M)*Theta_m(IJK,M)* Kth/ &
	               (RO_S(M)*SUM_EpsGo*Theta_m(IJK,M) + &
		       1.2d0*SWITCH*DgA/RO_S(M)* Kth)

	    ELSE
              Kth_star = RO_S(M)*EP_s(IJK,M)* G_0(IJK,M,M)*Theta_m(IJK,M)*Kth/ &
	               (RO_S(M)*SUM_EpsGo*Theta_m(IJK,M)+ &
		       (1.2d0*SWITCH*F_gs(IJK,M)*Kth/(RO_S(M)*EP_s(IJK,M))) )
            ENDIF
!
!           granular conductivity in Mth solids phase
            Kth_s(IJK,M) = Kth_star/G_0(IJK,M,M)*(&
                  ( ONE + (12d0/5.d0)*Eta*SUM_EpsGo )&
                  * ( ONE + (12d0/5.d0)*Eta*Eta*(4d0*Eta-3d0)&
                      *SUM_EpsGo )&
                  + (64d0/(25d0*Pi)) * (41d0-33d0*Eta) *&
                     (Eta*SUM_EpsGo)**2 &
              )
!
! implement Simonin and Ahmadi solids conductivities
            IF(SIMONIN) THEN

! Defining Simonin's Solids Turbulent Kinetic diffusivity: Kappa
  
              Kappa_kin = (9.d0/10.d0*K_12(ijk)*Nu_t + 3.0D0/2.0D0 * &
                 Theta_m(IJK,M)*(ONE+ Omega_c*EP_s(IJK,M)*G_0(IJK,M,M)))/&
                 (9.d0/(5.d0*Tau_12_st) + zeta_c/Tau_2_c)
          
              Kappa_Col = 18.d0/5.d0*EP_s(IJK,M)*G_0(IJK,M,M)*Eta* (Kappa_kin+ &
                     5.d0/9.d0*D_p(IJK,M)*DSQRT(Theta_m(IJK,M)/PI))
  
              Kth_s(IJK,M) =  EP_s(IJK,M)*RO_s(M)*(Kappa_kin + Kappa_Col)
!
            ELSE IF(AHMADI) THEN

! Defining Ahmadi conductivity from his equation 42 in Cao and Ahmadi 1995 paper
! note the constant 0.0711 is now 0.1306 because K = 3/2 theta_m
!
	      Kth_s(IJK,M) = 0.1306D0*RO_s(M)*D_p(IJK,M)*(ONE+C_e**2)* (  &
	                   ONE/G_0(IJK,M,M)+4.8D0*EP_s(IJK,M)+12.1184D0 &
			   *EP_s(IJK,M)*EP_s(IJK,M)*G_0(IJK,M,M) )  &
			   *DSQRT(Theta_m(IJK,M))
!
            ENDIF
 
!
!     granular 'conductivity' in the Mth solids phase associated
!     with gradient in volume fraction
 
!--------------------------------------------------------------------
!  Kphi_s has been set to zero.  To activate the feature uncomment the
!  following lines and also the lines in source_granular_energy.
            Kphi_s(IJK,M) = ZERO
!     &            (Kth_star/(G_0(IJK,M,M)))*(12d0/5.)*Eta*(Eta-1.)*
!     &            (2.*Eta-1.)*(1.+(12d0/5.)*Eta*EP_s(IJK,M)*
!     &            G_0(IJK,M,M))*(EP_s(IJK,M)*
!     &            DG_0DNU(EP_s(IJK,M))
!     &            + 2*G_0(IJK,M,M))*Theta_m(IJK,M)
!--------------------------------------------------------------------
 
!
!           Boyle-Massoudi stress coefficient
            ALPHA_s(IJK, M) = ZERO
          ENDIF
!
        ENDIF
!
  200 CONTINUE
!
! loezos 
   IF (SHEAR) THEN
!$omp parallel do private(IJK)
      Do IJK= ijkstart3, ijkend3
         IF (FLUID_AT(IJK)) THEN  	 
	   V_s(IJK,m)=V_s(IJK,m)-VSH(IJK)	
	 END IF
      END DO
   END IF
! loezos
      RETURN
      END

!// Comments on the modifications for DMP version implementation      
!// 001 Include header file and common declarations for parallelization 
!// 350 Changed do loop limits: 1,ijkmax2-> ijkstart3, ijkend3
