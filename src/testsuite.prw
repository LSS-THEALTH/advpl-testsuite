/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 NG Informática - TOTVS Software Partner
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include 'protheus.ch'

#define ANSI_CLEAR_SCREEN Chr( 27 ) + '[2J'
#define ANSI_MOVE_CURSOR_TO_HOME Chr( 27 ) + '[H'
#define ANSI_BEL Chr( 7 )
#define ANSI_SET_TITLE Chr( 27 ) + ']2;'
#define ANSI_YELLOW Chr( 27 ) + '[93m'
#define ANSI_RED Chr( 27 ) + '[91m'
#define ANSI_RESET Chr( 27 ) + '[0m'
#define ANSI_SAVE Chr( 27 ) + '7'
#define ANSI_RESTORE Chr( 27 ) + '8'
#define ANSI_YELLOW Chr( 27 ) + '[93m'
#define ANSI_BG_LIGHT_RED Chr( 27 ) + '[101m'
#define ANSI_BG_LIGHT_GREEN Chr( 27 ) + '[102m'
#define ANSI_BG_RESET Chr( 27 ) + '[49m'

Class TestSuite
    Data aErrors As Array
    Data cName As Character
    Data cDescription As Character
    Data oTester As Object
    Data oLogger As Object
    Data lVerbose As Logic
    Method New( cName, cDescription ) Constructor
    Method GetFeatures()
    Method Run( oTester )
    Method RunFeatures( aFeatures )
    Method RunBefore()
    Method ReportError( cFeature, cDescription, nStartedAt, oError )
    Method ReportEnd( cFeature, cDescription, nStartedAt )
    Method FormatStack( cStack )
    Method Expect( xExpr )
EndClass

Method New( cName, cDescription ) Class TestSuite
    ::aErrors := {}
    ::cName := cName
    ::cDescription := cDescription
    Return Self

Method FormatStack( cStack ) Class TestSuite
    Local cResult := ''
    Local aStack := StrTokArr2( cStack, Chr( 10 ), .T. )
    Local nIndex := 1
    Local nPos
    Local cStackFile
    Local aStackFiles := {}

    For nIndex := 1 To Len( aStack )
        If nIndex == 1
            cResult += aStack[ nIndex ] + CRLF
        Else
            If '(' $ aStack[ nIndex ] .And. '.PRW)' $ aStack[ nIndex ]
                nPos := At( '(', aStack[ nIndex ] )
                cStackFile := SubStr( aStack[ nIndex ], nPos + 1, At( ')', aStack[ nIndex ] ) - nPos - 1 )
                If aScan( aStackFiles, cStackFile ) == 0
                    aAdd( aStackFiles, cStackFile )
                EndIf
            EndIf

            cResult += Space( 30 ) + StrTran( aStack[ nIndex ], 'Called', ANSI_YELLOW + 'Called' + ANSI_RED ) + CRLF
        EndIf
    Next

    For nPos := 1 To Len( aStackFiles )
        cResult := StrTran( cResult, aStackFiles[ nPos ], ANSI_YELLOW + aStackFiles[ nPos ] + ANSI_RED )
    Next

    Return StrTran( cResult, 'THREAD ERROR', ANSI_YELLOW + 'THREAD ERROR' + ANSI_RED )

Method GetFeatures() Class TestSuite
    Local aMethods := ClassMethArr( ::oTester )
    Local aFeatures := {}
    Local nIndex
    For nIndex := 1 To Len( aMethods )
        If SubStr( aMethods[ nIndex, 1 ], 1, 5 ) == 'FEAT_'
            aAdd( aFeatures, Right( aMethods[ nIndex, 1 ], Len( aMethods[ nIndex, 1 ] ) - 5 ) )
        EndIf
    Next
    Return aFeatures

Method ReportError( cFeature, cDescription, nStartedAt, oError ) Class TestSuite
    Local cLine := Replicate( '-', Len( oError:Description ) + 4 )
    aAdd( ::aErrors, { cFeature, oError:Description } )
    ::oLogger:Error( '[{1}] {2} ({3}s)', { cFeature, cDescription, Seconds() - nStartedAt } )
    ::oLogger:Error( cLine )
    ::oLogger:Error( '| {1} |', { oError:Description } )
    ::oLogger:Error( cLine )
    ::oLogger:Error( ::FormatStack( oError:ErrorStack ) )
    Return Self

Method ReportEnd( cFeature, cDescription, nStartedAt ) Class TestSuite
    If aScan( ::aErrors, { |aError| aError[ 1 ] == cFeature } ) == 0
        ::oLogger:Success( '[{1}] {2} ({3}s)', { cFeature, cDescription, Seconds() - nStartedAt } )
    EndIf
    Return Self

Method RunFeatures( aFeatures ) Class TestSuite
    Local nIndex
    Local nCount
    Local nStartedAt
    Local cFeatDesc
    Local nReport
    Local cPercent
    Local nFinished := 0
    Local nPassed := 0
    Local nFailed := 0
    Local nTotal
    Local cPassed
    Local cFailed

    Private oThis := Self
    Private aTestReport := {}

    nCount := Len( aFeatures )
    For nIndex := 1 To nCount
        nStartedAt := Seconds()
        cFeatDesc := &( 'oThis:oTester:cDescription_Feat' + aFeatures[ nIndex ] )
        ErrorBlock( { |oError| Self:ReportError( aFeatures[ nIndex ], cFeatDesc, nStartedAt, oError ) })
        aTestReport := {}
        Begin Sequence
            &( 'oThis:oTester:Feat_' + aFeatures[ nIndex ] + '()' )
        End Sequence
        Self:ReportEnd( aFeatures[ nIndex ], cFeatDesc, nStartedAt )

        If ::lVerbose
            For nReport := 1 To Len( aTestReport )
                If aTestReport[ nReport, 1 ]
                    ::oLogger:Success( '    + ' + aTestReport[ nReport, 2 ] )
                    nPassed++
                Else
                    ::oLogger:Error( '    - ' + aTestReport[ nReport, 2 ] )
                    nFailed++
                EndIf
            Next
        EndIf

        nFinished++
        cPercent := AllTrim( Str( nFinished * 100 / nCount ) )
        ConOut( ANSI_SET_TITLE + '[' + cPercent + '% DONE] [' + ::cName + '] AdvPL Test Suite' + ANSI_BEL )
    Next

    If ::lVerbose
        nTotal := nPassed + nFailed
        nPassed := nPassed * 50 / nTotal
        cPassed := Replicate( ' ', Int( nPassed ) )
        cFailed := Replicate( ' ', Round( nFailed * 50 / nTotal, 0 ) )

        ::oLogger:Log( '{1}{2} {3}%', { ;
            ANSI_BG_LIGHT_GREEN + cPassed, ;
            ANSI_BG_LIGHT_RED + cFailed + ANSI_BG_RESET, ;
            AllTrim( Str( Round( nPassed * 2, 2 ) ) ) ;
        } )
    EndIf

    Return Self

Method RunBefore() Class TestSuite
    Local oFatalError
    Local bLastError := ErrorBlock({ |oError| oFatalError := oError })

    Begin Sequence
        If MethIsMemberOf( ::oTester, 'Before' )
            ::oTester:Before()
        EndIf
    End Sequence

    ErrorBlock( bLastError )

    If oFatalError != Nil
        ::oLogger:Error( 'Fatal error while running [Before], so I will not proceed' )
        ::oLogger:Error( ::FormatStack( oFatalError:ErrorStack ) )
        Return .F.
    EndIf
    Return .T.

Method Run( oTester ) Class TestSuite
    Local aFeatures
    Local bLastError
    Local aArea
    Local lRpcEnv
    Local nTime := Seconds()

    ::oTester := oTester
    aFeatures := ::GetFeatures()
    lRpcEnv := AttIsMemberOf( oTester, 'cDescription_Company' ) .And. AttIsMemberOf( oTester, 'cDescription_Branch' )

    ConOut( ANSI_SET_TITLE + '[' + ::cName + '] AdvPL Test Suite' + ANSI_BEL )
    ConOut( ANSI_CLEAR_SCREEN + ANSI_MOVE_CURSOR_TO_HOME )

    ::oLogger := Logger():New( ::cName )
    ::oLogger:Info( '[{1}] AdvPL Test Suite v0.1', { ::cName } )
    ::oLogger:Log( '> {1}, {2} feature(s)' + ANSI_SAVE, { ::cDescription, Len( aFeatures ) } )

    If lRpcEnv
        RpcSetEnv( oTester:cDescription_Company, oTester:cDescription_Branch )
        ConOut( ANSI_RESTORE )
        ::oLogger:Log( '> Running on {1} {2} {3}({4}s)', ;
            { oTester:cDescription_Company, oTester:cDescription_Branch, ANSI_YELLOW, Seconds() - nTime } )
    EndIf

    If !::RunBefore()
        Return Self
    EndIf

    bLastError := ErrorBlock()
    If lRpcEnv
        aArea := GetArea()
        Begin Transaction
            ::RunFeatures( aFeatures )
            DisarmTransaction()
            Break
        End Transaction
        RestArea( aArea )
    Else
        ::RunFeatures( aFeatures )
    EndIf
    ErrorBlock( bLastError )
    ::oLogger:Info( 'Ran {1} tests, {2} failed. Took {3}s', { Len( aFeatures ), Len( ::aErrors ), Seconds() - nTime } )
    Return Self

Method Expect( xExpr ) Class TestSuite
    Return FluentExpr():New( xExpr )