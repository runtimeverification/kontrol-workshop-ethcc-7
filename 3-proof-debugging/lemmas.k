requires "foundry.md"

module KONTROL-LEMMAS
    imports FOUNDRY


    rule bool2Word ( X ) => 1 requires X         [simplification]
    rule bool2Word ( X ) => 0 requires notBool X [simplification]

endmodule
