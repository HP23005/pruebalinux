;**************************************************************************
; PROGRAMA: Verificador de Palíndromos
; DESCRIPCIÓN: Este programa verifica si un número de hasta 10 dígitos es palíndromo
; FECHA: Junio 2025
;**************************************************************************

; --- MACRO para imprimir mensajes por pantalla ---
%macro PRINT 2
    mov eax, 4        ; Código de syscall para sys_write
    mov ebx, 1        ; Descriptor de salida estándar (stdout)
    mov ecx, %1       ; Dirección del mensaje a imprimir
    mov edx, %2       ; Longitud del mensaje
    int 0x80          ; Llamada al sistema
%endmacro

;**************************************************************************
; SECCIÓN DE DATOS
;**************************************************************************
section .data
    ; Mensaje que se muestra al usuario para solicitar un numero de hasta 10 digitos
    prompt      db "Ingresa numero (max 10 dig): ", 0
    prompt_len  equ $ - prompt  ; Longitud del mensaje

    ; Mensaje que se mostrará si la entrada es inválida
    inv_msg     db "Entrada invalida.",10,0
    inv_msg_len equ $ - inv_msg

    ; Mensaje si el número ingresado es un palíndromo
    yes_msg     db "Es palindromo.",10,0
    yes_msg_len equ $ - yes_msg

    ; Mensaje si el número ingresado no es un palíndromo
    no_msg      db "No es palindromo.",10,0
    no_msg_len  equ $ - no_msg

    ; Mensaje que muestra si desea continuar o finalizar el programa 
    ask_again   db "Deseas continuar? (S/N): ", 0
    ask_again_len equ $ - ask_again

;**************************************************************************
; SECCIÓN DE VARIABLES NO INICIALIZADAS
;**************************************************************************
section .bss
    ; Reservamos espacio para la entrada del usuario
    buf     resb 32   ; Buffer para almacenar la entrada (32 bytes para detectar exceso)
    len     resb 1    ; Variable para guardar la longitud real de la entrada
    again   resb 2    ; Variable para almacenar respuesta S/N

;**************************************************************************
; SECCIÓN DE CÓDIGO
;**************************************************************************
section .text
global _start

;**************************************************************************
; PUNTO DE ENTRADA DEL PROGRAMA
;**************************************************************************
_start:
main_loop:
    ; Solicitar entrada al usuario
    PRINT prompt, prompt_len
    
    ; Leer entrada del usuario
    mov eax, 3          ; syscall: sys_read
    mov ebx, 0          ; descriptor de entrada estándar (stdin)
    mov ecx, buf        ; puntero al buffer donde se almacenará la entrada
    mov edx, 32         ; número máximo de bytes a leer
    int 0x80
    mov [len], eax      ; guardamos la cantidad de bytes leídos

    ; Procesar y validar entrada
    call process_input
    call validate_input
    call check_palindrome
    jmp ask_continue

;**************************************************************************
; SUBRUTINA: process_input
; DESCRIPCIÓN: Elimina el salto de línea del final de la entrada
; MODIFICA: ecx, [len]
;**************************************************************************
process_input:
    mov ecx, [len]      ; Obtener longitud de la entrada
    dec ecx             ; Apuntar al último carácter
    cmp byte [buf + ecx], 10  ; Comparar con '\n'
    jne .done
    mov byte [buf + ecx], 0   ; Reemplazar '\n' con NULL
    mov [len], ecx      ; Actualizar longitud
.done:
    ret

;**************************************************************************
; SUBRUTINA: validate_input
; DESCRIPCIÓN: Verifica que la entrada sea válida (máximo 10 dígitos 0-9)
; UTILIZA: ecx para longitud, esi como contador, al para comparaciones
;**************************************************************************
validate_input:
    ; Verificar longitud máxima de 10 dígitos
    movzx ecx, byte [len]
    cmp ecx, 10
    ja invalid

    ; Verificar que todos sean dígitos
    xor esi, esi        ; Inicializar contador en 0
.check_digits:
    cmp esi, ecx        ; ¿Llegamos al final?
    jge .done           ; Si sí, la entrada es válida
    mov al, [buf + esi] ; Obtener carácter actual
    cmp al, '0'         ; ¿Es menor que '0'?
    jl invalid
    cmp al, '9'         ; ¿Es mayor que '9'?
    jg invalid
    inc esi             ; Siguiente carácter
    jmp .check_digits
.done:
    ret

;**************************************************************************
; SUBRUTINA: check_palindrome
; DESCRIPCIÓN: Verifica si el número es palíndromo comparando desde los extremos
; UTILIZA: esi (índice izquierdo), edi (índice derecho), al,bl (comparaciones)
;**************************************************************************
check_palindrome:
    xor esi, esi           ; Índice izquierdo inicia en 0
    movzx ecx, byte [len]
    mov edi, ecx           ; Índice derecho inicia al final
    dec edi
.compare:
    cmp esi, edi          ; ¿Se cruzaron los índices?
    jge pal_true          ; Si sí, es palíndromo
    mov al, [buf + esi]   ; Cargar carácter izquierdo
    mov bl, [buf + edi]   ; Cargar carácter derecho
    cmp al, bl            ; Comparar caracteres
    jne pal_false         ; Si no son iguales, no es palíndromo
    inc esi               ; Mover índice izquierdo
    dec edi               ; Mover índice derecho
    jmp .compare

;**************************************************************************
; ETIQUETAS PARA MOSTRAR RESULTADOS
;**************************************************************************
pal_true:
    PRINT yes_msg, yes_msg_len
    ret

pal_false:
    PRINT no_msg, no_msg_len
    ret

invalid:
    PRINT inv_msg, inv_msg_len
    jmp ask_continue

;**************************************************************************
; SUBRUTINA: ask_continue
; DESCRIPCIÓN: Pregunta al usuario si desea continuar (S/N)
;**************************************************************************
ask_continue:
    PRINT ask_again, ask_again_len
    
    ; Leer respuesta
    mov eax, 3
    mov ebx, 0
    mov ecx, again
    mov edx, 2
    int 0x80
    
    ; Verificar respuesta
    mov al, [again]
    cmp al, 'S'          ; ¿Es 'S'?
    je main_loop
    cmp al, 's'          ; ¿Es 's'?
    je main_loop

;**************************************************************************
; SALIDA DEL PROGRAMA
;**************************************************************************
exit:
    mov eax, 1           ; syscall: sys_exit
    xor ebx, ebx         ; código de salida 0
    int 0x80             ; llamada al sistema
