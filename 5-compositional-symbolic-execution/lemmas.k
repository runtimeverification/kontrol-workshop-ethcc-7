requires "foundry.md"

module KONTROL-LEMMAS
    imports FOUNDRY
    imports INT-SYMBOLIC
    imports MAP-SYMBOLIC
    imports SET-SYMBOLIC

    //
    // Equality of +Bytes
    //

   rule { B:Bytes #Equals B1:Bytes +Bytes B2:Bytes } =>
           { #range ( B, 0, lengthBytes(B1) ) #Equals B1 } #And
           { #range ( B, lengthBytes(B1), lengthBytes(B) -Int lengthBytes(B1) ) #Equals B2 }
      requires lengthBytes(B) ==Int lengthBytes(B1 +Bytes B2)
      [simplification(60), concrete(B)]

    rule { B1:Bytes +Bytes B2:Bytes #Equals B } =>
           { #range ( B, 0, lengthBytes(B1) ) #Equals B1 } #And
           { #range ( B, lengthBytes(B1), lengthBytes(B) -Int lengthBytes(B1) ) #Equals B2 }
      requires lengthBytes(B1 +Bytes B2) ==Int lengthBytes(B)
      [simplification(60), concrete(B)]

    rule { B1:Bytes +Bytes B2:Bytes #Equals B3:Bytes +Bytes B4:Bytes } =>
         { #range(B1, 0, minInt(lengthBytes(B1), lengthBytes(B3))) #Equals #range(B3, 0, minInt(lengthBytes(B1), lengthBytes(B3))) } #And
         { #range(B1, minInt(lengthBytes(B1), lengthBytes(B3)), lengthBytes(B1) -Int minInt(lengthBytes(B1), lengthBytes(B3))) +Bytes B2
             #Equals
           #range(B3, minInt(lengthBytes(B1), lengthBytes(B3)), lengthBytes(B1) -Int minInt(lengthBytes(B1), lengthBytes(B3))) +Bytes B4 }
         [simplification(60), concrete(B1, B3)]

    rule { B #Equals #buf( N, X:Int ) } => { #asWord ( B ) #Equals X }
      requires lengthBytes(B) ==Int N andBool N <=Int 32
       andBool 0 <=Int X andBool 0 <Int 2 ^Int (8 *Int N)
      [simplification(80), concrete(B, N)]

    //
    // Equality of #asWord
    //
    rule { X:Int #Equals #asWord ( B:Bytes ) } => { #buf ( 32, X ) #Equals B }
      requires #rangeUInt(256, X) andBool lengthBytes( B ) ==Int 32
      [simplification, concrete(X), preserves-definedness]

    //
    // keccak assumptions: these assumptions are not sound in principle, but are
    // required for verification - they should be collected at the end of execution
    //

    rule 0 <=Int keccak( _ )             => true [simplification, smt-lemma]
    rule         keccak( _ ) <Int pow256 => true [simplification, smt-lemma]

    // keccak does not equal a concrete value
    rule [keccak-eq-conc-false]: keccak(_A)  ==Int _B => false [symbolic(_A), concrete(_B), simplification(30), comm]
    rule [keccak-neq-conc-true]: keccak(_A) =/=Int _B => true  [symbolic(_A), concrete(_B), simplification(30), comm]
    rule [keccak-eq-conc-false-ml-lr]: { keccak(A) #Equals B } => { true #Equals keccak(A) ==Int B } [symbolic(A), concrete(B), simplification]
    rule [keccak-eq-conc-false-ml-rl]: { B #Equals keccak(A) } => { true #Equals keccak(A) ==Int B } [symbolic(A), concrete(B), simplification]

    // keccak is injective
    rule [keccak-inj]: keccak(A) ==Int keccak(B) => A ==K B [simplification]
    rule [keccak-inj-ml]: { keccak(A) #Equals keccak(B) } => { true #Equals A ==K B } [simplification]

    // chop of negative keccak
    rule chop (0 -Int keccak(BA)) => pow256 -Int keccak(BA)
       [simplification]

    // keccak cannot equal a number outside of its range
    rule { X #Equals keccak (_) } => #Bottom
      requires X <Int 0 orBool X >=Int pow256
      [concrete(X), simplification]

    //
    // Arithmetic
    //
    rule A ==Int B *Int C => C ==Int A /Int B
      requires 0 <Int B andBool A modInt B ==Int 0
      [simplification, concrete(A, B), preserves-definedness]
      

    //
    // Map and #lookup reasoning
    //
    rule [map-update-idem]: M:Map [ K:Int <- #lookup(N:Map, K) ] => M requires #lookup(M, K) ==K #lookup(N, K) [simplification(40)]


endmodule
