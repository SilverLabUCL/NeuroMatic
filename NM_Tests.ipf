#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//****************************************************************
//****************************************************************

Function NMUtilityTest()

	if ( !NMTestVarEqual( 0, 0 ) || !NMTestVarEqual( NaN, NaN ) )
		Print "NM test failure: " + GetRTStackInfo( 3 ); Abort
	endif
	
	if ( !NMTestVarEqual( -inf, -inf ) || !NMTestVarEqual( inf, inf ) )
		Print "NM test failure: " + GetRTStackInfo( 3 ); Abort
	endif
	
	if ( !NMTestVarNotEqual( -1, 1 ) || !NMTestVarNotEqual( 0, NaN ) || !NMTestVarNotEqual( 0, inf ) )
		Print "NM test failure: " + GetRTStackInfo( 3 ); Abort
	endif
	
	if ( !NMTestVarNotEqual( inf, -inf ) || !NMTestVarNotEqual( NaN, inf ) )
		Print "NM test failure: " + GetRTStackInfo( 3 ); Abort
	endif

	NMTestVarEqual( NMInequality( 0, greaterThan=-1 ), 1 )
	NMTestVarEqual( NMInequality( 0, greaterThan=0 ), 0 )
	NMTestVarEqual( NMInequality( 0, greaterThan=1 ), 0 )
	NMTestVarEqual( NMInequality( 0, greaterThan=NaN ), 0 )
	NMTestVarEqual( NMInequality( 0, greaterThan=-inf ), 1 )
	NMTestVarEqual( NMInequality( 0, greaterThan=inf ), 0 )
	
	NMTestVarEqual( NMInequality( 0, greaterThanOrEqual=-1 ), 1 )
	NMTestVarEqual( NMInequality( 0, greaterThanOrEqual=0 ), 1 )
	NMTestVarEqual( NMInequality( 0, greaterThanOrEqual=1 ), 0 )
	NMTestVarEqual( NMInequality( 0, greaterThanOrEqual=NaN ), 0 )
	NMTestVarEqual( NMInequality( 0, greaterThanOrEqual=-inf ), 1 )
	NMTestVarEqual( NMInequality( 0, greaterThanOrEqual=inf ), 0 )
	
	NMTestVarEqual( NMInequality( 0, lessThan=-1 ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThan=0 ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThan=1 ), 1 )
	NMTestVarEqual( NMInequality( 0, lessThan=NaN ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThan=-inf ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThan=inf ), 1 )
	
	NMTestVarEqual( NMInequality( 0, lessThanOrEqual=-1 ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThanOrEqual=0 ), 1 )
	NMTestVarEqual( NMInequality( 0, lessThanOrEqual=1 ), 1 )
	NMTestVarEqual( NMInequality( 0, lessThanOrEqual=NaN ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThanOrEqual=-inf ), 0 )
	NMTestVarEqual( NMInequality( 0, lessThanOrEqual=inf ), 1 )
	
	NMTestVarEqual( NMInequality( 0, equal=-1 ), 0 )
	NMTestVarEqual( NMInequality( 0, equal=0 ), 1 )
	NMTestVarEqual( NMInequality( 0, equal=NaN ), 0 )
	NMTestVarEqual( NMInequality( NaN, equal=NaN ), 1 )
	NMTestVarEqual( NMInequality( -inf, equal=NaN ), 0 )
	NMTestVarEqual( NMInequality( inf, equal=NaN ), 0 )
	NMTestVarEqual( NMInequality( 0, equal=-inf ), 0 )
	NMTestVarEqual( NMInequality( NaN, equal=-inf ), 0 )
	NMTestVarEqual( NMInequality( -inf, equal=-inf ), 1 )
	NMTestVarEqual( NMInequality( inf, equal=-inf ), 0 )
	NMTestVarEqual( NMInequality( 0, equal=inf ), 0 )
	NMTestVarEqual( NMInequality( NaN, equal=inf ), 0 )
	NMTestVarEqual( NMInequality( -inf, equal=inf ), 0 )
	NMTestVarEqual( NMInequality( inf, equal=inf ), 1 )
	
	NMTestVarEqual( NMInequality( 0, notEqual=-1 ), 1 )
	NMTestVarEqual( NMInequality( 0, notEqual=0 ), 0 )
	NMTestVarEqual( NMInequality( 0, notEqual=NaN ), 1 )
	NMTestVarEqual( NMInequality( NaN, notEqual=NaN ), 0 )
	NMTestVarEqual( NMInequality( -inf, notEqual=NaN ), 1 )
	NMTestVarEqual( NMInequality( inf, notEqual=NaN ), 1 )
	NMTestVarEqual( NMInequality( 0, notEqual=-inf ), 1 )
	NMTestVarEqual( NMInequality( NaN, notEqual=-inf ), 1 )
	NMTestVarEqual( NMInequality( -inf, notEqual=-inf ), 0 )
	NMTestVarEqual( NMInequality( inf, notEqual=-inf ), 1 )
	NMTestVarEqual( NMInequality( 0, notEqual=inf ), 1 )
	NMTestVarEqual( NMInequality( NaN, notEqual=inf ), 1 )
	NMTestVarEqual( NMInequality( -inf, notEqual=inf ), 1 )
	NMTestVarEqual( NMInequality( inf, notEqual=inf ), 0 )
	
	NMTestVarEqual( NMInequality( 0, greaterThan=-1, lessThan=1 ), 1 )
	NMTestVarEqual( NMInequality( 0, greaterThan=-1, lessThan=0 ), 0 )
	
	Print "Finished NMUtilityTest"
	
End // NMUtilityTest