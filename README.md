# AES128-Encryption-and-Decrytion-in-Verilog
Welcome to the AES128 encryption and decryption repository, featuring automatic testing equipment (ATE) for function verification.

Key Features

  Both the encryption and decryption building blocks are tapeout verified and exhibit flawless functionality.

  Encryption Block

    Operates at a clock speed of 10MHz.
    UART communication is configured at 115200 bps with odd parity check.

  Decryption Block

    Operates at a clock speed of 5MHz.
    UART communication is set at 115200 bps with even parity check.

How to Use the Crypto System

  Follow these steps to utilize the cryptographic system:

    Input a 128-bit encryption key into the chip via the UART interface. Ensure that you include a 0x0D,0x0A end symbol after 16 transitions to indicate the end of key input.
    Once the key is successfully buffered, input the 128-bit plaintext or ciphertext into the chip. Again, conclude with a 0x0D,0x0A end symbol.
    The internal AES module will process the information and send the result through UART, including an end symbol to signify completion.

Testing and Verification

  The encryption chip has undergone rigorous testing on an ATE:

    Approximately 12 million tests were conducted.
    A staggering 594 MB of data was transmitted to the chip via UART, with no communication errors or data inconsistencies reported.

  These extensive tests confirm the reliability and robust performance of the system.
