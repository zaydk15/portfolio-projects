package crc_ref_pkg;

    // Compute CRC-16/CCITT (poly=0x1021, init=0xFFFF) for a byte array
    function automatic bit [15:0] crc16_ref(input byte data[]);
        bit [15:0] crc = 16'hFFFF;
        foreach (data[i]) begin
            // XOR input byte into MSB of CRC, then do 8 shifts
            crc ^= (data[i] << 8);
            repeat (8) begin
                if (crc[15]) crc = (crc << 1) ^ 16'h1021;
                else         crc = (crc << 1);
            end
        end
        return crc;
    endfunction

endpackage
