module alu(flags, result, inst, reg_a, reg_b);

    input[31:0] inst, reg_a, reg_b;
    wire[5:0] opcode; //Opcode storing
    reg[5:0] func; //Function code storing

    reg[31:0] ALU_result; 
    reg[2:0] ALU_flags; 
    reg[31:0] RS, RT; 
    assign opcode = inst[31:26];

    output signed [31:0] result;
    output[2:0] flags;
    logic extend; //Used for sign extension

    always @(inst, reg_a, reg_b) begin
        
        // RT Assignment
        if(inst[20:16] == 5'b00000) RT = reg_a;
        else if (inst[25:21] == 5'b00001) RT = reg_b;
        else RT = 0;

        // RS Assignment
        if (inst[25:21] == 5'b00000) RS = reg_a;
        else if (inst[25:21] == 5'b00001) RS = reg_b;
        else RS = 0;

        case (opcode)

            /* For R-type insts */
            6'b000000: begin

                func = inst[5:0];

                case(func)

                    6'b100000: //Add inst
                    begin
                        {extend, ALU_result} = $signed({RS[31], RS}) + $signed({RT[31], RT}); //Sign extending and adding
                        ALU_flags[2] = ({extend, ALU_result[31]} == 2'b01 || {extend, ALU_result[31]} == 2'b10); //Overflow detection
                        if ($signed(ALU_result) < 32'd0) ALU_flags[1] = 1'b1; 
                        else if (ALU_result == 32'd0) ALU_flags[0] = 1'b1;
                    end

                    6'b100010: //Sub inst
                    begin              
                        {extend, ALU_result} = $signed({RS[31], RS}) - $signed({RT[31], RT}); //Sign extending and subracting
                        ALU_flags[2] = ({extend, ALU_result[31]} == 2'b01 || {extend, ALU_result[31]} == 2'b10); //Overflow detection
                        if ($signed(ALU_result) < 32'd0) ALU_flags[1] = 1'b1; 
                        else if (ALU_result == 32'd0) ALU_flags[0] = 1'b1; 
                    end    

                    6'b100001:  ALU_result = RS + RT; //Addu inst

                    6'b100011: ALU_result = RS - RT; //Subu inst

                    6'b000000: ALU_result = RT << inst[10:6]; //Sll inst

                    6'b000100: ALU_result = RT << RS; //Sllv inst

                    6'b000010: ALU_result = RT >> inst[10:6]; //Srl inst

                    6'b000110: ALU_result = RT >> RS; //Srlv inst

                    6'b000011: ALU_result = RT >>> inst[10:6]; //Sra inst

                    6'b000111: ALU_result = RT >>> RS; //Srav inst

                    6'b100100: ALU_result = RS & RT; //And inst

                    6'b100111: ALU_result = ~(RS | RT); //Nor inst

                    6'b100101: ALU_result = RS | RT; //Or inst

                    6'b100110: ALU_result = RS ^ RT; //Xor inst

                    6'b101010: begin //Slt inst
                        
                        ALU_result = ($signed(RS) < $signed(RT)) ? 1 : 0; 

                        if(ALU_result) ALU_flags[1] = 1'b1; 

                    end

                    6'b101011: begin //Sltu inst
                        
                        ALU_result = (RS < RT) ? 1 : 0; 

                        if(ALU_result) ALU_flags[1] = 1'b1; 

                    end

                endcase
            end

            /* For I-type insts */
            6'b001000: //Addi inst
            begin 
                {extend, ALU_result} = $signed({RS[31], RS}) + $signed({{17{inst[15]}}, inst[15:0]}); //Sign extending and adding
                ALU_flags[2] = ({extend, ALU_result[31]} == 2'b01 || {extend, ALU_result[31]} == 2'b10); //Overflow Detection
                if($signed(ALU_result) < 32'd0) ALU_flags[1] = 1'b1; 
                else if (ALU_result == 32'd0) ALU_flags[0] = 1'b1; 
            end

            6'b001001: ALU_result = RS + {{16{inst[15]}}, inst[15:0]}; //Addiu inst

            6'b001100: ALU_result = RS & {{16{1'b0}},inst[15:0]}; //Andi inst

            6'b001101: ALU_result = RS | {{16{1'b0}},inst[15:0]}; //Ori inst

            6'b001110: ALU_result = RS ^ {{16{1'b0}},inst[15:0]}; //Xori inst

            6'b000100: begin //Beq inst
                if($signed(RS) == $signed(RT)) ALU_result = inst[15:0];
                else begin
                    ALU_result = 0;
                    ALU_flags[0] = 1'b1;
                end
            end

            6'b000101: begin //Bne instruction
                if($signed(RS) == $signed(RT)) begin
                    ALU_result = 0;
                    ALU_flags[0] = 1'b1;   
                end
                else ALU_result = inst[15:0];
            end

            6'b001010: begin //Slti inst
               
                ALU_result = ($signed(RS) < $signed({{16{inst[15]}}, inst[15:0]})) ? 1 : 0; 
                if(ALU_result) ALU_flags[1] = 1'b1; 

            end

            6'b001011: begin //Sltiu inst
                
                ALU_result = RS < {{16{inst[15]}}, inst[15:0]} ? 1 : 0; 
                if(ALU_result) ALU_flags[1] = 1'b1; 

            end

            6'b100011: ALU_result = $signed(RT) + $signed({{16{inst[15]}}, inst[15:0]}); //Lw inst

            6'b101011: ALU_result = $signed(RT) + $signed({{16{inst[15]}}, inst[15:0]}); //Sw inst

        endcase
    end
                   
    assign result = ALU_result;
    assign flags = ALU_flags;

endmodule