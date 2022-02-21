.data
newline: .string "\n"
listInput: .string "ADD(1)~ADD(a)~ADD()~ADD(B)~ADD~ADD(9)~PRINT~SORT(a)~PRINT~DEL(bb)~DEL(B)~ PRINT~REV~PRINT"
#listInput: .string "ADD(1)~ADD(a)~ADD(a)~ADD(B)~ADD(;)~ADD(9)~PRINT~SORT~PRINT~DEL(b)~DEL(B)~PRI~ REV~ PRINT"
#listInput: .string "REV         ~ SORT ~ ADD(aa)~DEL(b)~ADD(4)~ADD(f)~ADD(F)~ADD(-)~ADD(4)~ADD(4)~PRINT~SORT~PRINT~DEL(4)~REV~PRINT"
lfsr: .word 372198

.text
lw s0 lfsr # seed per la generazione degli indirizzi di memoria
li s1 0 # puntatore alla testa della linked list inizializzato a zero
li s2 0 # puntatore alla coda della linked list inizializzato a zero
la s4 listInput # puntatore lista dei comandi in input

add a1 s4 zero # copia del puntatore alla testa listInput

# Nel main viene soltanto eseguito un salto incondizionato al DECODING

main: 
    j DECODING

# funzione ADD che aggiunge un nodo alla linked list

ADD:
    # Come primo passo si esegue una jal ad "address_generator" per ottenere un indirizzo di memoria
    # che sarà salvato in a3
    jal address_generator
    bne s1 zero not_first_ADD # se s1 != 0 esiste già una testa della linked list che quindi non deve essere creata
    
    # se il controllo precedente fallisce significa che non e' stata creata nessuna lista, quindi si salva in 4(a3)
    # il valore a2 ricevuto dal DECODING e si mettono vuoti i puntatori al precedente e al successivo
    add s1 a3 zero
    li t0 0xffffffff
    sw t0 0(a3) #PBACK del primo nodo
    sw t0 5(a3) #PAHEAD del primo nodo
    sb a2 4(a3) # salva il valore la prima volta
    add s2 a3 zero # viene aggiornato il puntatore alla coda della linked list
    j DECODING # la prima ADD è stata eseguita e si può tornare al DECODING
    
    # viene aggiunto un nodo in coda alla linked list salvando a2 nel byte opportuno e aggiornando i puntatori del nuovo nodo
    # e del precedente
    not_first_ADD:
        li t0 0xffffffff
        sb a2 4(a3) # valore di input dalla stringa listInput
        sw t0 5(a3) # PAHEAD dell'ultimo nodo
        sw a3 5(s2) # il nuovo indirizzo viene salvato come PAHEAD del precedente ultimo nodo
        sw s2 0(a3) # puntatore alla coda precedente salvato come PBACK del nuovo nodo
        add s2 a3 zero # aggiornamento del puntatore alla coda 
     j DECODING # ADD eseguita e ritorno al DECODING

# Funzione PRINT che stampa una stringa composta da tutti i valori della lista

PRINT:
    
    # La testa della lista viene salvata in un registro temporaneo e controlla che sia stata fatta
    # almeno una ADD
    li t0 0xffffffff
    add t1 s1 zero # copia della testa
    beq t1 zero DECODING # se non e' stata fatta nessuna ADD torna al decoding
    
    # il primo controllo si assicura che in caso si sia arrivati in fondo alla lista venga stampato il carattere "\n"
    # dopodiché si salva in a0 il carattere da stampare, lo si stampa, si passa all'elemento successivo e si ripete la procedura
    PRINT_loop:
        beq t0 t1 new_line
        lb a0 4(t1) # valore da stampare
        li a7 11 # si utilizza la system call apposita per i caratteri
        ecall
        lw t1 5(t1) # la copia alla testa viene aggiornata al nodo successivo
        j PRINT_loop
        new_line:
            la a0 newline # caricato in a0 "\n"
            li a7 4
            ecall
            j DECODING # la PRINT e' conclusa quindi si torna al DECODING

# Funzione DEL che ricerca e elimina il nodo desiderato

DEL:
    
    # Primi quattro comandi analoghi alla funzione PRINT
    li t0 0xffffffff
    add t1 s1 zero
    beq t1 zero DECODING # se non e' stata fatta nessuna ADD torna al decoding
    
    # Nel registro t2 viene caricato l'elemento della lista da controllare, se e' uguale all'elemento a2 da eleminare
    # salta alla label apposita, altrimenti avanza al nodo successivo fino a che non si arriva all'ultimo, in quel caso
    # si torna al DECODING
    DEL_loop:
        lb t2 4(t1) # elemento da confrontare
        beq a2 t2 delete_element # se a2 == t2 l'elemento da eliminare è stato trovato e si salta a "delete_element"
        lw t1 5(t1) # aggiornamento della testa temporanea al nodo successivo
        beq t1 t0 DECODING # torna al DECODING se a fine lista
        j DEL_loop
        
    # elimnina il nodo se e' in una posizione intermedia, altrimenti salta ai label adibiti
    delete_element:
        lw t4 0(t1) # PBACK del nodo selezionato nel "DEL_loop"
        lw t5 5(t1) # PAHEAD del nodo selezionato
        beq t0 t4 del_first_element # se il PBACK è vuoto si salta a "del_first_element"
        beq t0 t5 del_last_element # se il PAHEAD è vuoto si salta a "del_last_element"
        sw t5 5(t4) # PAHEAD del nodo precedente a quello da eliminare salvato nel successivo successivo
        sw t4 0(t5) # PBACK del nodo successivo salvato nel precedente
        # mette a zero gli indirizzi di memoria occupati dal nodo da eliminare, quinid torna al DECODING
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        j DECODING # il nodo e' stato eliminato e si torna al DECODING
        
    # se il controllo a riga 92 ha successo si controlla che non ci sia solo un nodo, in questo caso
    # si aggiornano i puntatori del primo e del secondo nodo e si elimina il primo
    del_first_element:
        beq t0 t5 del_only_element # se il nodo e' l'unico salta alla label "del_only_element"
        sw t0 0(t5) # mette vuoto il PAHEAD del secondo nodo
        
        # libera la memoria occupata dal primo nodo
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        add s1 t5 zero # aggiorna il puntatore alla testa della lista
        j DECODING 
        
    # elimina l'unico nodo presente nella linked list
    del_only_element:
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        add s1 zero zero # resetta la testa della lista a 0 poiche' adesso è vuota
        j DECODING
        
    # elimina l'ultimo nodo
    del_last_element:
        sw t0 5(t4) # mette vuoto il PAHEAD del penultimo ultimo nodo
        
        # libera la memoria
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        add s2 t4 zero # aggiorna il puntatore della coda al nuovo ultimo nodo
        j DECODING

# Funzione SORT che ordina gli elementi della lista tramite l'implementazione 
# del bubble sort

SORT:
    beq s1 zero DECODING
    add t1 s1 zero # copia del puntatore alla testa della linked list
    li t0 0 # FLAG settata a 0
    
    # il loop va avanti finche' l'elemento più grande non si trova in coda alla lista
    SORT_loop:
        lb a4 4(t1) # carica elemento corrente
        lw t3 5(t1) # carica PAHEAD al secondo elemento, con cui confrontare, e PBACK al primo
        lb a5 4(t3) # carica elemento con cui confrontare
        li t5 0xffffffff # per controllo a fine coda
        beq t3 t5 check_swapped # controlla se si è arrivati a fine coda, in caso salta a "check_swapped"
        jal swap_check # viene chiamata una funzione che ritorna a2 == 1 se gli elementi confrontati sono da scambiare, 0 altrimenti
        bne a2 zero swap_element # se a2 != 0 salta a "swap_element"
        add t1 t3 zero # aggiorna il puntatore temporaneo alla testa della linked list
        j SORT_loop
        
    # se la condizione a riga 156 è soddisfatta si procede a scambiare i due elementi in esame
    swap_element:
        sb a4 4(t3) # salva il primo elemento al posto del secondo
        sb a5 4(t1) # salva il secondo elemento al posto del primo
        li t0 1 # variabile FLAG che conferma che uno scambio è avvenuto
        add t1 t3 zero # aggiorna la testa della linked list
        j SORT_loop
    check_swapped:
        beq t0 zero DECODING # se non e' stato fatto nessuno scambio (t0 == 0) la lista e' ordinata e si torna al decoding
        j SORT

# FUnzione che inverte il PAHEAD e il PBACK di ogni nodo per ottenere una lista invertita

REV:
    li t0 0xffffffff
    beq s1 zero DECODING # se la lista è vuota torna al DECODING
    add t1 s1 zero # salva la testa della lista nel registro temporaneo t1
    
    # ad ogni iterazione del REV_loop vengono caricati il PAHEAD e il PBACK del nodo corrente,
    # successivamente vengono invertiti e si passa al nodo successivo
    REV_loop:
        lw t4 0(t1) # PBACK del nodo corrente
        lw t5 5(t1) # PAHEAD del nodo corrente
        add t3 t5 zero # nel registro t3 temporaneo viene salvato il PAHEAD del nodo corrente prima chevenga invertito 
        
        # si scambiano i puntatori
        sw t4 5(t1)
        sw t5 0(t1)
        beq t1 t0 head_rear_swap # se si e' arrivati a fine coda salta a "head_rear_swap"
        add t1 t3 zero # aggiornamento del puntatore al nodo successivo
        j REV_loop
        
    # si scambiano i puntatori alla testa e alla coda della linked list
    head_rear_swap:
        add t2 s2 zero # salva il puntatore alla coda s2 in un registro temporaneo t2
        add s2 s1 zero # copia in s2 il puntatore alla testa s1
        add s1 t2 zero # copia in s1 la copia t2 di s2
        j DECODING # la lista è invertita e torna al DECODING
        
# funzione ausiliaria che genera numeri pseudo-casuali ad ogni rilevazione di una ADD, 
address_generator:
    
    # 4 shift a destra del seed lfsr
    srli t0 s0 0
    srli t1 s0 2
    srli t2 s0 3
    srli t3 s0 5
    
    # xor tra i quattro risultati degli shift
    xor t0 t0 t1
    xor t0 t0 t2
    xor t0 t0 t3
    
    # shift a destra dell' lfsr e a sinistra del bit ottenuto dagli xor, messi poi in or
    srli t1 s0 1
    slli t0 t0 15
    or t1 t1 t0
    
    # considerazione di soltanto 16 bit dell'output 
    li t4 0x0000ffff
    and t1 t1 t4
    li t4 0x00010000
    or a3 t1 t4 # a3 indirizzo generato pseudo casuale
    add s0 a3 zero # uso dell'indirizzo generato come seed per la prossima generazione
    
    # controllo per assicurarsi che la memoria sia libera
    add t0 a3 zero
    lw t1 0(t0)
    bne t1 zero address_generator # se la memoria e' occupata genera un nuovo indirizzo
    lb t1 4(t0)
    bne t1 zero address_generator
    lw t1 5(t0)
    bne t1 zero address_generator
    jr ra

# Funzione ausiliaria che controlla se i due elementi a4, a5 presi dal sort devono essere scambiati

swap_check:
    
    # controlla se il primo elemento a4 e' una lettera maiuscola, in caso positivo controlla l'intervallo
    # del secondo valore di input a5
    check_first:
        li t2 65 # t2 e' il registro dove si caricano i limiti degli intervalli di interesso per l'ordinamento
        blt a4 t2 check_number_first # se il valore ASCII di a4 < 65 si salta a "check_number_first"
        li t2 90
        bgt a4 t2 check_minuscola_first # se a4 > 90 si salta a "check_minuscola_first"
        li t4 4 # nel registro t4 viene salvata la priorità di a4, in questo caso "4" e' la priorità corrispondente alle maiuscole
        j check_second # salto al controllo del secondo elemento a5
        
    # controlla se il primo elemento e' una lettera minuscola
    check_minuscola_first:
        li t2 97
        blt a4 t2 set_special_char_first # se a4 < 97 non è una minuscola allora e' un carattere speciale
        li t2 122
        bgt a4 t2 set_special_char_first # anche se a4 > 122 allora e' un carattere speciale
        li t4 3 # se e' una minuscola la priorità di a4 viene messa a 3
        j check_second # salta al controllo del secondo elemento
        
    # controlla se a4 è un numero
    check_number_first:
        li t2 48
        blt a4 t2 set_special_char_first # se a4 < 48 è un carattere speciale
        li t2 57
        bgt a4 t2 set_special_char_first # se a4 > 57 è un carattere speciale
         li t4 2 # se a4 e' un carattere speciale ha priorità 2
        j check_second # salta al controllo del secondo elemento
    set_special_char_first:
        li t4 1 # se a4 e' un carattere speciale ha priorità 1
        
    # controlla l'intervallo di appartenza di a5 e lo salva in t6 seguendo lo stesso algoritmo usato per a4
    # ma una volta ottenuta la priorità di a5 la confronta con quella di a4
    check_second:
        li t2 65
        blt a5 t2 check_number_second
        li t2 90
        bgt a5 t2 check_minuscola_second
        li t6 4 # priorità primo valore
        j check_priority # salto al confronto di t4 e t6, priorità di a4 e a5
    check_minuscola_second:
        li t2 97
        blt a5 t2 set_special_char_second
        li t2 122
        bgt a5 t2 set_special_char_second
        li t6 3
        j check_priority
    check_number_second:
        li t2 48
        blt a5 t2 set_special_char_second
        li t2 57
        bgt a5 t2 set_special_char_second
        li t6 2
        j check_priority
    set_special_char_second:
        li t6 1
    check_priority:
        li a2 0 # a2 resettato a 0 per evitare errori su controlli successivi
        bgt t4 t6 set_swapper # se t4 > t6 allora a4 > a5 e salta a "set_swapper"
        beq t4 t6 check_elements # se t4 == t6 si confrontano a4 e a5
        jr ra
    
    # confronto tra i due elementi
    check_elements:
        bgt a4 a5 set_swapper # se a4 > a5 salto a "set_swapper"
        jr ra
    set_swapper:
        li a2 1 # a2 viene messo a 1 se si devono scambiare i due elementi
        jr ra 

# Funzione DECODING che si occupa di decodificare la stringa di input che ha l'indirizzo salvato in a1 

DECODING:
    
    # loop che ignora ogni spazio in listInput
    check_initial_spaces:
        lb t1 0(a1) # carica il carattere da controllare
        li t2 32 # space
        bne t1 t2 CHECK_ADD # se non e' uno spazio salta a "CHECK_ADD", altrimenti incrementa a1 di 1 per puntare al carattere successivo 
        addi a1 a1 1
        j check_initial_spaces # ricomincia il loop
    
    # il CHEK_ADD controlla se l'istruzione corrente e' una ADD, esaminando carattere per carattere,
    # se fallisce passa all'istruzione successiva
    CHECK_ADD:
        
        check_A:
            lb t1 0(a1) # in t1 viene caricato il carattere da controllare
            li t2 65 # in t2 viene caritato il carattere ASCII da controllare, in questo caso A
            beq t1 t2 check_D1 # se t1 == A passa al controllo per la prima D
            j CHECK_PRINT # se fallisce il controllo per la A salta a "CHECK_PRINT"
        check_D1:
            addi a1 a1 1 # sposta la testa della listInput di una posizione in avanti
            lb t1 0(a1)
            li t2 68 # D
            beq t1 t2 check_D2 # se t1 == D salta al controllo per la seconda D
            j check_next_instruction # se fallisce il controllo significa che l'istruzione è formattata male e salta a quella dopo
        check_D2:
            addi a1 a1 1
            lb t1 0(a1)
            li t2 68 # D
            beq t1 t2 check_value_ADD # se t1 == D controlla la formattazione del valore da aggiungere
            j check_next_instruction
            
        # check per le parentesi e il valore di input della ADD
        check_value_ADD: 
             addi a1 a1 1
             lb t1 0(a1)
             li t2 40 # open par
             bne t1 t2 check_next_instruction # se il check per parentesi aperta fallisce salta all'istruzione successiva
             addi a1 a1 1
             lb a2 0(a1) # salva in a2 il valore in input per la ADD
             
             # controllo accettabilità del valore di input, se a2 < 32 e a2 > 125 salta alla prossima istruzione
             # altrimenti controlla che la formattazione dell'istruzione si completi correttamente 
             li t2 32
             blt a2 t2 check_next_instruction
             li t2 125
             bgt a2 t2 check_next_instruction
             addi a1 a1 1
             lb t1 0(a1)
             li t2 41 # closed par
             bne t1 t2 check_next_instruction # se t1 == ")" lettura dell'istruzione successiva
        
        # ingora eventuali spazi e avanza il puntatore a1 fino alla prossima tilde o fino al fine stringa 
        check_correct_format_ADD:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 32 # space
             bne t1 t2 check_next_tilde
             j check_correct_format_ADD
             check_next_tilde:
                 lb t1 0(a1)
                 li t2 126 # tilde
                 beq t1 t2 ADD # se viene rilevata una tilde la formattazione e' corretta e si chiama la ADD
                 lb t1 0(a1)
                 li t2 0 # end of string
                 bne t1 t2 check_next_instruction # se il primo carattere dopo eventuali spazi non e' ne' una tilde nel il fine stringa, salta all'istruzione successiva
                 j ADD # chiama la ADD se si e' arrivati a fine stringa
                 
     # segue la stessa implementazione del CHECK_ADD ma senza il controllo del valore di input poiché
     # non ce n'e' bisogno e richiama la PRINT se la formattazione è corretta
     CHECK_PRINT:
         
         check_P:
             lb t1 0(a1)
             li t2 80 # T
             beq t1 t2 check_R1
             j CHECK_DEL   
         check_R1:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 82 # R
             beq t1 t2 check_I
             j check_next_instruction
         check_I:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 73 # I
             beq t1 t2 check_N
             j check_next_instruction
         check_N:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 78 # N
             beq t1 t2 check_T1
             j check_next_instruction             
         check_T1:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 84 # T
             bne t1 t2 check_next_instruction
             check_correct_format_PRINT:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32 # space
                 bne t1 t2 check_tilde_PRINT
                 j check_correct_format_PRINT
                 check_tilde_PRINT:
                     lb t1 0(a1)
                     li t2 126 # tilde
                     beq t1 t2 PRINT
                     lb t1 0(a1)
                     li t2 0 # EOS
                     bne t1 t2 check_next_instruction
                     j PRINT
                     
     # CHECK_DEL segue la stessa implementazione della ADD, ma richiama la DEL
     # se la formattazione è corretta
     CHECK_DEL:
         
         check_D3:
             lb t1 0(a1)
             li t2 68 # D
             beq t1 t2 check_E1
             j CHECK_SORT             
         check_E1:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 69 # E
             beq t1 t2 check_L
             j check_next_instruction             
         check_L:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 76 # L
             beq t1 t2 check_value_DEL
             j check_next_instruction
         check_value_DEL:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 40 # open par
             bne t1 t2 check_next_instruction
             addi a1 a1 1
             lb a2 0(a1) # contiene l'elemento da elimnare
             addi a1 a1 1
             lb t1 0(a1)
             li t2 41 # closed par
             bne t1 t2 check_next_instruction
             check_correct_format_DEL:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32 # space
                 bne t1 t2 check_tilde_DEL
                 j check_correct_format_DEL
                 check_tilde_DEL:
                     lb t1 0(a1)
                     li t2 126 # tilde
                     beq t1 t2 DEL
                     lb t1 0(a1)
                     li t2 0 # EOS
                     bne t1 t2 check_next_instruction
                     j DEL
     
     # stessa implementazione del CHECK_PRINT, ma richiama il SORT               
     CHECK_SORT:
         
         check_S:
             lb t1 0(a1)
             li t2 83 # S
             beq t1 t2 check_O
             j CHECK_REV
         check_O:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 79 # O
             beq t1 t2 check_R2
             j check_next_instruction
         check_R2:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 82 # R
             beq t1 t2 check_T2
             j check_next_instruction
         check_T2:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 84 # T
             bne t1 t2 check_next_instruction
             check_correct_format_SORT:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32 # space
                 bne t1 t2 check_tilde_SORT
                 j check_correct_format_SORT
                 check_tilde_SORT:
                     lb t1 0(a1)
                     li t2 126 # tilde
                     beq t1 t2 SORT
                     lb t1 0(a1)
                     li t2 0 # EOS
                     bne t1 t2 check_next_instruction
                     j SORT
     
     # stessa implementazione del CHECK_PRINT, ma richiama la REV     
     CHECK_REV:
         
         check_R3:
             lb t1 0(a1)
             li t2 82 # R
             beq t1 t2 check_E2
             j check_next_instruction             
         check_E2:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 69 # E
             beq t1 t2 check_V
             j check_next_instruction
         check_V:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 86 # V
             bne t1 t2 check_next_instruction
             check_correct_format_REV:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32 # space
                 bne t1 t2 check_tilde_REV
                 j check_correct_format_REV
                 check_tilde_REV:
                     lb t1 0(a1)
                     li t2 126 # tilde
                     beq t1 t2 REV
                     lb t1 0(a1)
                     li t2 0 # EOS
                     bne t1 t2 check_next_instruction
                     j REV
     
     # funzione ausiliaria che cerca una eventuale nuova istruzione
     check_next_instruction:
         
         # loop per ignorare degli eventuali spazi
         check_spaces:
             lb t1 0(a1)
             li t2 32 # spazio
             bne t1 t2 check_tilde # se il carattere e' diverso da uno spazio salta a "check_tilde"
             addi a1 a1 1
             j check_spaces
             
         # loop che scorre i caratteri fino alla prossima tilde
         check_tilde:
             lb t1 0(a1)
             li t2 126 # tilde
             beq t1 t2 next # se il carattere in esame e' una tilde salta a "next"
             addi a1 a1 1
             lb t1 0(a1)
             li t3 0
             beq t1 t3 exit # controlla se si e' arrivati a fine stringa, in caso si esce dal programma
             j check_tilde
         next:
             addi a1 a1 1 # passa al carattere successivo alla tilde trovata
             j DECODING # ritrona al DECODING per un eventuale prossima istruzione

# uscita dal programma 
exit:
li a7 10
ecall