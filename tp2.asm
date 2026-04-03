; =============================================================================
; contador_8bit.asm
; Descripcion : Contador de 8 bits con pulsador en RD0 y LEDs en PORTB
; Micro       : PIC16F887
; Cristal     : 4 MHz (XT)
; Reset       : /MCLR (pulsador externo)
; Compilador  : MPASM (MPLAB X IDE)
; =============================================================================

    LIST        P=16F887
    #INCLUDE    <P16F887.INC>

; -----------------------------------------------------------------------------
; BITS DE CONFIGURACION
; -----------------------------------------------------------------------------
    __CONFIG    _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG    _CONFIG2, _BOR40V & _WRT_OFF

; -----------------------------------------------------------------------------
; VARIABLES EN BANCO 0 (GPR: 0x20 - 0x7F)
; -----------------------------------------------------------------------------
    CBLOCK  0x20
        CONTADOR        ; Valor actual del contador (0-255)
        TEMP_DEBOUNCE   ; Registro auxiliar para antirebote
    ENDC

; Constante para el lazo de antirebote (~20ms a 4MHz)
DEBOUNCE_COUNT  EQU     0xFF

; =============================================================================
; VECTOR DE RESET
; =============================================================================
    ORG     0x0000
    GOTO    INICIO

; =============================================================================
; INICIO - CONFIGURACION DE PUERTOS
; =============================================================================
    ORG     0x0005

INICIO:
    ; --- Banco 1: configurar direccion de pines ---
    BSF     STATUS, RP0         ; Seleccionar Banco 1

    ; PORTB -> todos como SALIDAS (LEDs)
    CLRF    TRISB               ; TRISB = 0x00

    ; PORTD -> RD0 como ENTRADA (pulsador), resto salidas
    MOVLW   0x01
    MOVWF   TRISD               ; RD0 = entrada, RD1-RD7 = salidas

    ; Deshabilitar conversores A/D en PORTB y PORTD
    ; ANSEL  controla AN0-AN7  (pines del PORTA y PORTE)
    ; ANSELH controla AN8-AN13 (pines del PORTB)
    BSF STATUS, RP1
    CLRF    ANSEL               ; AN0-AN7 digitales
    CLRF    ANSELH              ; AN8-AN13 digitales (PORTB digital)

    ; --- Banco 0: inicializar puertos y variables ---
    BCF     STATUS, RP0
    BCF	    STATUS, RP1	; Seleccionar Banco 0

    CLRF    PORTB               ; Apagar todos los LEDs
    CLRF    PORTD               ; Limpiar PORTD
    CLRF    CONTADOR            ; Iniciar contador en 0

    ; Mostrar valor inicial (0x00) en los LEDs
    MOVF    CONTADOR, W
    MOVWF   PORTB

; =============================================================================
; LOOP PRINCIPAL
; =============================================================================
LOOP:
    ; Leer RD0 (pulsador: activo en bajo, con pull-up externo)
    BTFSC   PORTD, 0            ; ¿RD0 = 0? (pulsador presionado)
    GOTO    LOOP                ; No -> seguir esperando

    ; --- Pulsador detectado: antirebote ---
    CALL    DEBOUNCE

    ; Verificar nuevamente que sigue presionado (confirmar)
    BTFSC   PORTD, 0
    GOTO    LOOP                ; Era ruido, ignorar

    ; --- Incrementar contador ---
    INCF    CONTADOR, F         ; CONTADOR++ (desbordamiento: 255 -> 0 automatico)

    ; Mostrar nuevo valor en los LEDs
    MOVF    CONTADOR, W
    MOVWF   PORTB

    ; --- Esperar a que se suelte el pulsador (evitar multiples conteos) ---
ESPERAR_SOLTAR:
    BTFSS   PORTD, 0            ; ¿RD0 = 1? (soltado)
    GOTO    ESPERAR_SOLTAR      ; No -> seguir esperando

    ; Antirebote al soltar
    CALL    DEBOUNCE

    GOTO    LOOP                ; Volver al inicio del loop

; =============================================================================
; SUBRUTINA: DEBOUNCE (~20ms a 4MHz)
; Cada ciclo del lazo interno = 3 instrucciones = 3us
; 0xFF iteraciones x 3us ~= 765us por pasada del lazo externo
; Lazo externo x DEBOUNCE_COUNT ~= ~20ms total
; =============================================================================
DEBOUNCE:
    MOVLW   DEBOUNCE_COUNT
    MOVWF   TEMP_DEBOUNCE
DEBOUNCE_LOOP:
    NOP                         ; 1 ciclo
    NOP                         ; 1 ciclo
    DECFSZ  TEMP_DEBOUNCE, F    ; 1 ciclo (salta si llega a 0)
    GOTO    DEBOUNCE_LOOP
    RETURN

; =============================================================================
    END