!vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvC
!                                                                      C
!  Module name: EOSG (MW, PG, TG)                                      C
!  Purpose: Equation of state for gas                                  C
!                                                                      C
!  Author: M. Syamlal                                 Date: 29-JAN-92  C
!  Reviewer: P. Nicoletti, W. Rogers, S. Venkatesan   Date: 29-JAN-92  C
!                                                                      C
!  Revision Number:                                                    C
!  Purpose:                                                            C
!  Author:                                            Date: dd-mmm-yy  C
!  Reviewer:                                          Date: dd-mmm-yy  C
!                                                                      C
!  Literature/Document References:                                     C
!                                                                      C
!  Variables referenced: GAS_CONST                                     C
!  Variables modified: EOSG                                            C
!                                                                      C
!  Local variables: None                                               C
!                                                                      C
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^C
!
      DOUBLE PRECISION FUNCTION EOSG (MW, PG, TG,J) 
!...Translated by Pacific-Sierra Research VAST-90 2.06G5  12:17:31  12/09/98  
!...Switches: -xf
!JD - modifying to include a height dependent eos --- this helps correct
!for atmospheric temp. gradients
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE param 
      USE param1 
      USE constant
      USE physprop
      USE scales
      USE geometry 
      IMPLICIT NONE
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      INTEGER J
      DOUBLE PRECISION MW, PG, TG 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      DOUBLE PRECISION :: XXX 
!-----------------------------------------------
      INCLUDE 'sc_p_g1.inc'
      INCLUDE 'sc_p_g2.inc'
!

IF (ATMOSPHERIC) THEN
  !Note modification need to be made if using an irregular grid
  IF (REAL(J)*DY(50)<=TROPOPAUSE) THEN
       EOSG = UNSCALE(PG)*MW/(GAS_CONST*(TG-.0098*DY(50)*REAL(J)))
   ELSE
      EOSG=UNSCALE(PG)*MW/(GAS_CONST*(TG-.0098*TROPOPAUSE+REAL(J)*DY(50)*.001))
   END IF
 ELSE

      EOSG = UNSCALE(PG)*MW/(GAS_CONST*TG) 
 END IF
!
      RETURN  
      END FUNCTION EOSG 
!
!vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvC
!                                                                      C
!  Module name: dROodP_g(ROG, PG)                                      C
!  Purpose: derivative of gas density w.r.t pressure                   C
!                                                                      C
!  Author: M. Syamlal                                 Date: 14-AUG-96  C
!                                                                      C
!  Revision Number:                                                    C
!  Purpose:                                                            C
!  Author:                                            Date: dd-mmm-yy  C
!  Reviewer:                                          Date: dd-mmm-yy  C
!                                                                      C
!  Literature/Document References:                                     C
!                                                                      C
!  Variables referenced: GAS_CONST                                     C
!  Variables modified: EOSG                                            C
!                                                                      C
!  Local variables: None                                               C
!                                                                      C
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^C
!
      DOUBLE PRECISION FUNCTION DROODP_G (ROG, PG) 
!...Translated by Pacific-Sierra Research VAST-90 2.06G5  12:17:31  12/09/98  
!...Switches: -xf
!
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE param 
      USE param1 
      USE constant
      USE physprop
      USE scales 
      IMPLICIT NONE
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
!                      gas density
!
!                      Gas pressure
      DOUBLE PRECISION ROG, PG 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
!-----------------------------------------------
!
!
      DROODP_G = ROG/(PG + P_REF) 
!
      RETURN  
      END FUNCTION DROODP_G 
