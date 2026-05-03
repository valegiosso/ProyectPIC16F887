; =============================================================================
; Contador_7seg_TP3.asm
; Trabajo Practico de Laboratorio N3 - Sistemas con Microcontroladores
; Autores : Garbagnoli, Giosso, Verdinelli
; Fecha   : Abril 2026
;
; Descripcion:
;   Contador de 0 a 9 que incrementa su valor cada vez que se presiona
;   un pulsador conectado a RD0. El valor se visualiza en un display de
;   7 segmentos de ANODO COMUN. El anodo comun va conectado directamente
;   a VDD (sin transistor, display unico siempre habilitado).
;
;   En anodo comun, un segmento se ENCIENDE con nivel BAJO (0) en el pin.
;   Por lo tanto los patrones de la tabla son el complemento de los de
;   catodo comun: 0 = segmento encendido, 1 = segmento apagado.
;
; Hardware:
;   - Microcontrolador : PIC16F887
;   - Cristal externo  : 4 MHz (modo XT)
;   - Reset            : MCLR con resistencia pull-up a VDD
;   - Pulsador         : RD0, activo en bajo, pull-up externo de 10k a VDD
;   - Display          : 7 segmentos ANODO COMUN
;                        Anodo comun -> VDD (directo, sin transistor)
;   - Segmentos a-g    : RB0-RB6 (via resistencias de 330 ohm)
;   - Compilador       : MPASM (MPLAB X IDE)
;
; Calculo de resistencias limitadoras:
;   R = (VCC - VF) / IF = (5.0 - 1.8) / 0.010 = 320 ohm
;   Se usan 330 ohm (valor comercial mas proximo).
;   IF resultante = (5.0 - 1.8) / 330 = 9.7mA  -> dentro del rango seguro.
;
; Mapa de segmentos en PORTB:
;   RB6=g | RB5=f | RB4=e | RB3=d | RB2=c | RB1=b | RB0=a  | RB7=no usado
;
;           aaa
;          f   b
;          f   b
;           ggg
;          e   c
;          e   c
;           ddd
;
; =============================================================================

    LIST    P=16F887
    #INCLUDE <P16F887.INC>

; --- Bits de Configuracion ---
; XT     -> cristal externo 4 MHz
; WDT    -> watchdog off
; PWRTE  -> Power-up Timer on (espera 72ms para estabilizar VDD)
; MCLRE  -> pin MCLR habilitado como reset externo
; LVP    -> Low Voltage Programming off (libera RB3 como I/O)
; BOREN  -> Brown-out Reset on
    __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    __CONFIG _CONFIG2, _BOR40V & _WRT_OFF

; --- Variables en RAM - Banco 0 (0x20 a 0x7F) ---
    CBLOCK  0x20
        CONTADOR    ; Valor actual del contador (0 a 9)
        TEMP_1      ; Contador externo del doble lazo de debounce
        TEMP_2      ; Contador interno del doble lazo de debounce
    ENDC

; --- Constantes de debounce ---
; Tiempo total = DBNC_OUTER x DBNC_INNER x 3us = 26 x 248 x 3us = 19.3ms
DBNC_OUTER  EQU .26
DBNC_INNER  EQU .248

; =============================================================================
; VECTOR DE RESET
; =============================================================================
    ORG     0x0000
    GOTO    INICIO

; =============================================================================
; TABLA DE CONVERSION BCD -> 7 SEGMENTOS (ANODO COMUN, 0 = enciende segmento)
;
; Los valores son el complemento bit a bit de los de catodo comun.
; Ejemplo: catodo comun "0" = 0b00111111 = 0x3F
;          anodo comun  "0" = 0b11000000 = 0xC0
;
; Ubicada en ORG 0x0010 para no cruzar limite de pagina (256 words).
; =============================================================================
    ORG     0x0010
TABLA_7SEG:
    ADDWF   PCL, F          ; PC = PC + W  ->  salta a la entrada del digito
    ; Bits: RB7 RB6 RB5 RB4 RB3 RB2 RB1 RB0
    ;         1   g   f   e   d   c   b   a
    ;       (RB7 siempre 1 = apagado, no conectado)
    ;       0 = segmento encendido | 1 = segmento apagado
    RETLW   b'11000000'     ; 0 -> enciende a b c d e f     = 0xC0
    RETLW   b'11111001'     ; 1 -> enciende b c             = 0xF9
    RETLW   b'10100100'     ; 2 -> enciende a b d e g       = 0xA4
    RETLW   b'10110000'     ; 3 -> enciende a b c d g       = 0xB0
    RETLW   b'10011001'     ; 4 -> enciende b c f g         = 0x99
    RETLW   b'10010010'     ; 5 -> enciende a c d f g       = 0x92
    RETLW   b'10000010'     ; 6 -> enciende a c d e f g     = 0x82
    RETLW   b'11111000'     ; 7 -> enciende a b c           = 0xF8
    RETLW   b'10000000'     ; 8 -> enciende a b c d e f g   = 0x80
    RETLW   b'10010000'     ; 9 -> enciende a b c d f g     = 0x90

; =============================================================================
; INICIO - CONFIGURACION DE PUERTOS
; =============================================================================
    ORG     0x0020
INICIO:
    ; --- Banco 1: configurar direccion de pines (registros TRIS) ---
    BSF     STATUS, RP0         ; seleccionar banco 1

    CLRF    TRISB               ; PORTB todo salida -> segmentos a-g del display
    MOVLW   0x01
    MOVWF   TRISD               ; RD0 entrada (pulsador), RD1-RD7 salidas

    ; --- Banco 3: deshabilitar modulos analogicos ---
    ; Los pines arrancan en modo ANALOGICO por defecto.
    ; Si no se pasan a modo digital, las lecturas y escrituras de puerto
    ; no funcionan aunque TRIS este correctamente configurado.
    BSF     STATUS, RP1         ; banco 3 (RP0=1 y RP1=1)
    CLRF    ANSEL               ; AN0-AN7  -> modo digital
    CLRF    ANSELH              ; AN8-AN13 -> modo digital (incluye pines PORTB)

    ; --- Banco 0: volver al banco de trabajo ---
    BCF     STATUS, RP0
    BCF     STATUS, RP1

    ; --- Condiciones iniciales ---
    ; En anodo comun, todos los pines en 1 = todos los segmentos APAGADOS.
    MOVLW   0xFF
    MOVWF   PORTB               ; apagar todos los segmentos al arrancar
    CLRF    PORTD               ; limpiar PORTD
    CLRF    CONTADOR            ; el contador arranca en 0

    ; Mostrar el 0 inicial en el display
    MOVF    CONTADOR, W
    CALL    TABLA_7SEG
    MOVWF   PORTB

; =============================================================================
; LOOP PRINCIPAL - Polling del pulsador
; =============================================================================
LOOP:
    BTFSC   PORTD, 0            ; RD0 = 0? (pulsador presionado = nivel bajo)
    GOTO    LOOP                ; no -> seguir esperando

    ; --- Antirebote al presionar (~19.3ms) ---
    CALL    DEBOUNCE
    BTFSC   PORTD, 0            ; confirmar que sigue presionado tras el retardo
    GOTO    LOOP                ; era ruido -> ignorar

    ; --- Pulsacion confirmada: incrementar contador ---
    INCF    CONTADOR, F         ; CONTADOR++

    ; Verificar limite: si CONTADOR llego a 10, reiniciar a 0
    MOVLW   d'10'
    SUBWF   CONTADOR, W         ; W = CONTADOR - 10 (no modifica CONTADOR)
    BTFSC   STATUS, Z           ; Z=1 si CONTADOR == 10
    CLRF    CONTADOR            ; si llego a 10 -> volver a 0

    ; --- Actualizar display con el nuevo valor ---
    MOVF    CONTADOR, W
    CALL    TABLA_7SEG
    MOVWF   PORTB

    ; --- Esperar a que el usuario suelte el pulsador ---
ESPERAR_SOLTAR:
    BTFSS   PORTD, 0            ; RD0 = 1? (pulsador suelto = nivel alto)
    GOTO    ESPERAR_SOLTAR      ; no -> seguir esperando

    ; --- Antirebote al soltar ---
    CALL    DEBOUNCE

    GOTO    LOOP                ; volver al inicio

; =============================================================================
; SUBRUTINA DEBOUNCE - Retardo ~19.3ms @ 4MHz
;
; Doble lazo anidado:
;   Lazo interno: NOP + NOP + DECFSZ = 3 ciclos = 3us por iteracion
;   Cuando TEMP_2 llega a 0 se decrementa TEMP_1 y el lazo vuelve a
;   empezar con TEMP_2 = 0 -> decrementa a 0xFF (255 iteraciones nuevas).
;
;   Total = 26 x 248 x 3us = 19.344ms
; =============================================================================
DEBOUNCE:
    MOVLW   DBNC_OUTER
    MOVWF   TEMP_1
    MOVLW   DBNC_INNER
    MOVWF   TEMP_2
DEBOUNCE_LOOP:
    NOP                         ; 1 ciclo de espera
    NOP                         ; 1 ciclo de espera
    DECFSZ  TEMP_2, F           ; TEMP_2-- ; si = 0 -> saltear siguiente
    GOTO    DEBOUNCE_LOOP       ; TEMP_2 != 0 -> continuar lazo interno
    DECFSZ  TEMP_1, F           ; TEMP_2 = 0 -> TEMP_1-- ; si = 0 -> saltear
    GOTO    DEBOUNCE_LOOP       ; TEMP_1 != 0 -> reiniciar lazo interno
    RETURN                      ; TEMP_1 = 0 -> fin del retardo

    END