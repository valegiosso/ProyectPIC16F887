; ============================================================
; Trabajo Práctico - Contador de 8 bits con PIC16F886
; Descripción: Cuenta pulsaciones en RA4 y muestra el valor
;              en binario natural sobre los 8 LEDs del Puerto B.
; Cristal:     4 MHz  ?  ciclo de instrucción = 1 µs
; Autor:       Garbagnoli, Giosso, Verdinelli
; Fecha:       2026
; ============================================================

#include <p16f887.inc>
	    
; --- Definición de variables en RAM (Banco 0) ---
CONTADOR    equ     0x20        ; Registro de 8 bits: valor del contador (0?255)
REG_1       equ     0x21        ; Variable auxiliar para el retardo (lazo externo)
REG_2       equ     0x22        ; Variable auxiliar para el retardo (lazo interno)

            ORG     0x00        ; Vector de reset
            GOTO    SETUP

; ============================================================
; SETUP: Configuración inicial de puertos y registros
; ============================================================
SETUP:
    ; --- Configurar dirección de los pines (Banco 1) ---
    BANKSEL TRISA
    BSF     TRISA, 4            ; RA4 como ENTRADA (pulsador)
    CLRF    TRISB               ; Puerto B completo como SALIDA (8 LEDs)

    ; --- Deshabilitar entradas analógicas (Banco 1) ---
    BANKSEL ANSEL
    CLRF    ANSEL               ; AN0?AN7 como digitales (incluye RA4/AN3)
    CLRF    ANSELH              ; AN8?AN11 como digitales

    ; --- Inicializar puertos y contador (Banco 0) ---
    BANKSEL PORTB
    CLRF    PORTB               ; Apagar todos los LEDs al inicio
    CLRF    CONTADOR            ; Contador comienza en 0

; ============================================================
; ESPERAR_PRESION: Espera activa hasta detectar flanco
;                 descendente en RA4 (botón presionado = 0)
; ============================================================
ESPERAR_PRESION:
    BTFSC   PORTA, 4            ; ¿RA4 = 0? (pulsado)
    GOTO    ESPERAR_PRESION     ; No ? seguir esperando

    ; --- Anti-rebote: esperar 20 ms y confirmar ---
    CALL    RETARDO_20MS

    ; --- Incrementar contador y actualizar LEDs ---
    INCF    CONTADOR, F         ; CONTADOR = CONTADOR + 1 (wraps 255?0 automáticamente)
    MOVF    CONTADOR, W         ; W = CONTADOR giosso la concha de tu hermana
    MOVWF   PORTB               ; Mostrar los 8 bits en los LEDs

; ============================================================
; ESPERAR_SOLTAR: Espera a que el usuario suelte el botón
;                para evitar contar múltiples veces por
;                una sola pulsación.
; ============================================================
ESPERAR_SOLTAR:
    BTFSS   PORTA, 4            ; ¿RA4 = 1? (botón suelto)
    GOTO    ESPERAR_SOLTAR      ; No ? seguir esperando

    ; --- Anti-rebote al soltar ---
    CALL    RETARDO_20MS

    GOTO    ESPERAR_PRESION     ; Volver al inicio del ciclo

; ============================================================
; RETARDO_20MS: Subrutina de retardo de aproximadamente 20 ms
; Cálculo (cristal 4 MHz ? T_inst = 1 µs):
;   Lazo interno:  255 iter × 2 ciclos (DECFSZ+GOTO) = 510 µs
;   + 1 ciclo MOVLW + 1 ciclo MOVWF = 512 µs por vuelta exterior
;   Lazo externo:   39 iter × 512 µs = 19.968 ms ? 20 ms
; ============================================================
RETARDO_20MS:
    MOVLW   D'39'               ; 39 iteraciones del lazo externo
    MOVWF   REG_1
LOOP1:
    MOVLW   D'255'              ; 255 iteraciones del lazo interno
    MOVWF   REG_2
LOOP2:
    DECFSZ  REG_2, F            ; REG_2-- ; si = 0, salta la sig. instrucción
    GOTO    LOOP2               ; Seguir lazo interno
    DECFSZ  REG_1, F            ; REG_1-- ; si = 0, salta la sig. instrucción
    GOTO    LOOP1               ; Seguir lazo externo
    RETURN                      ; Retornar al programa principal

            END