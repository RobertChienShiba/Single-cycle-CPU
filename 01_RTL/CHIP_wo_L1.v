//----------------------------- DO NOT MODIFY THE I/O INTERFACE!! ------------------------------//
module CHIP #(                                                                                  //
    parameter BIT_W = 32                                                                        //
)(                                                                                              //
    // clock                                                                                    //
        input               i_clk,                                                              //
        input               i_rst_n,                                                            //
    // instruction memory                                                                       //
        input  [BIT_W-1:0]  i_IMEM_data,                                                        //
        output [BIT_W-1:0]  o_IMEM_addr,                                                        //
        output              o_IMEM_cen,                                                         //
    // data memory                                                                              //
        input               i_DMEM_stall,                                                       //
        input  [BIT_W-1:0]  i_DMEM_rdata,                                                       //
        output              o_DMEM_cen,                                                         //
        output              o_DMEM_wen,                                                         //
        output [BIT_W-1:0]  o_DMEM_addr,                                                        //
        output [BIT_W-1:0]  o_DMEM_wdata,                                                       //
    // finnish procedure                                                                        //
        output              o_finish,                                                           //
    // cache                                                                                    //
        input               i_cache_finish,                                                     //
        output              o_proc_finish                                                       //
);                                                                                              //
//----------------------------- DO NOT MODIFY THE I/O INTERFACE!! ------------------------------//

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Parameters
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    // TODO: any declaration
    //====== op code ======
    // R-type
    localparam ADD   = 7'b0110011;
    localparam SUB   = 7'b0110011;
    localparam AND   = 7'b0110011;
    localparam XOR   = 7'b0110011;
    localparam MUL   = 7'b0110011;
    // I-type
    localparam ADDI  = 7'b0010011;
    localparam SLLI  = 7'b0010011;
    localparam SRAI  = 7'b0010011;
    localparam SLTI  = 7'b0010011;
    localparam LW    = 7'b0000011;
    // B-type
    localparam BEQ   = 7'b1100011;
    localparam BGE   = 7'b1100011;
    localparam BLT   = 7'b1100011;
    localparam BNE   = 7'b1100011;
    // S-type
    localparam SW    = 7'b0100011;
    // J-type
    localparam JAL   = 7'b1101111;
    localparam JALR  = 7'b1100111;
    // U-type
    localparam AUIPC = 7'b0010111;
    // ecall
    localparam ECALL = 7'b1110011 ;
    //====== funct3 ======
    localparam ADD_FUNC3  = 3'b000;
    localparam SUB_FUNC3  = 3'b000;
    localparam AND_FUNC3  = 3'b111;
    localparam XOR_FUNC3  = 3'b100;
    localparam ADDI_FUNC3 = 3'b000;
    localparam SLLI_FUNC3 = 3'b001;
    localparam SRAI_FUNC3 = 3'b101;
    localparam SLTI_FUNC3 = 3'b010;
    localparam MUL_FUNC3  = 3'b000;
    localparam BEQ_FUNC3  = 3'b000;
    localparam BGE_FUNC3  = 3'b101;
    localparam BLT_FUNC3  = 3'b100;
    localparam BNE_FUNC3  = 3'b001;
    //====== funct7 ======
    localparam ADD_FUNC7 = 7'b0000000;
    localparam SUB_FUNC7 = 7'b0100000;
    localparam AND_FUNC7 = 7'b0000000;
    localparam XOR_FUNC7 = 7'b0000000;
    localparam MUL_FUNC7 = 7'b0000001;

    // FSM state
    localparam S_IDLE        = 0;
    localparam S_EXEC        = 1;
    localparam S_EXEC_MULDIV = 2;

    // RegWrite Src
    localparam ADD_W    = 0;
    localparam SUB_W    = 1;
    localparam AND_W    = 2;
    localparam XOR_W    = 3;
    localparam MUL_W    = 4;
    localparam ADDI_W   = 5;
    localparam SLLI_W   = 6;
    localparam SRAI_W   = 7;
    localparam SLTI_W   = 8;
    localparam LW_W     = 9;
    localparam AUIPC_W  = 10;
    localparam JAL_W    = 11;
    localparam JALR_W   = 12;


// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Wires and Registers
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // TODO: any declaration
        reg [BIT_W-1:0] PC, PC_nxt;
        // reg inst_cen, inst_cen_nxt;
        reg mem_cen, mem_wen;
        reg  hold; 
        reg [BIT_W-1:0] mem_addr, mem_wdata, mem_rdata;
        wire mem_stall;
        reg  regWrite   ;  
        wire  [ 4:0] rs1, rs2, rd;              
        wire [BIT_W-1:0] rs1_data    ;              
        wire [BIT_W-1:0] rs2_data    ;             
        reg  [BIT_W-1:0] rd_data     ; 
        wire  [6:0 ] op_code_w;
        wire  [BIT_W-1:0] inst_w;
        reg  [1:0 ] state_w, state_r;
        wire  [2:0 ] funct3_w;
        wire  [6:0 ] funct7_w;
        reg  [BIT_W-1:0] imm_w;
        
        reg         mulDiv_valid;
        wire        mulDiv_done;
        wire  [2:0]  mulDiv_inst;
        wire  [BIT_W-1:0] mulDiv_in_A, mulDiv_in_B;
        wire [2*BIT_W-1:0] mulDiv_out;  

        reg  finish, finish_nxt;  
        reg  branch_control, condition;  
        wire jump;      

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Continuous Assignment
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: any wire assignment
    assign o_finish = i_cache_finish;
    assign o_proc_finish = finish;
    // assign o_finish = finish;
    assign o_IMEM_cen = 1;
    assign o_IMEM_addr = PC;
    assign o_DMEM_addr = mem_addr;
    assign o_DMEM_wdata = mem_wdata;
    assign o_DMEM_wen = mem_wen;
    assign o_DMEM_cen = mem_cen;

    // ----------------------- Decoding --------------------------
    assign inst_w = i_IMEM_data;
    assign op_code_w = inst_w[6:0];
    assign funct3_w = inst_w[14:12];
    assign funct7_w = inst_w[31:25];
    assign rs1 = inst_w[19:15];
    assign rs2 = inst_w[24:20];
    assign rd  = inst_w[11:7];
    assign jump = (branch_control & condition);
    // ----------------------- MulDiv input --------------------------
    assign mulDiv_in_A = rs1_data;
    assign mulDiv_in_B = rs2_data;
    assign mulDiv_inst = 3'd6;
    // ----------------------- Memory install --------------------------
    assign mem_stall = i_DMEM_stall;
// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Submoddules
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: Reg_file wire connection
    Reg_file reg0(               
        .i_clk  (i_clk),             
        .i_rst_n(i_rst_n),         
        .wen    (regWrite),          
        .rs1    (rs1),                
        .rs2    (rs2),                
        .rd     (rd),                 
        .wdata  (rd_data),             
        .rdata1 (rs1_data),           
        .rdata2 (rs2_data)
    );

    MULDIV_unit mulDiv0(
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n), 
        .i_valid(mulDiv_valid), 
        .i_inst(mulDiv_inst), 
        .i_A(mulDiv_in_A), 
        .i_B(mulDiv_in_B), 
        .o_data(mulDiv_out), 
        .o_done(mulDiv_done)
    );

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Always Blocksrd_data 
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    // Todo: any combinational/sequential circuit
    // Decode Instruction
    always @(*) begin
        rd_data = 0;
        imm_w = 0;
        mem_addr = 0;
        mem_wdata = 0;
        mem_wen = 0;
        mem_cen = 0;
        regWrite= 0;
        mulDiv_valid = 0;
        condition = 0;
        branch_control = 0;
        case (op_code_w)
            7'b0110011: begin
                regWrite= 1'b1;
                case ({funct7_w, funct3_w})
                    {ADD_FUNC7, ADD_FUNC3}: begin
                        rd_data = $signed(rs1_data) + $signed(rs2_data);
                    end
                    {SUB_FUNC7, SUB_FUNC3}: begin
                        rd_data = $signed(rs1_data) - $signed(rs2_data);
                    end
                    {AND_FUNC7, AND_FUNC3}:begin
                        rd_data = rs1_data & rs2_data;
                    end
                    {XOR_FUNC7, XOR_FUNC3}: begin
                        rd_data = rs1_data ^ rs2_data;
                    end
                    {MUL_FUNC7, MUL_FUNC3}: begin
                        regWrite= (mulDiv_done)?1'b1:1'b0;
                        mulDiv_valid = 1'b1;
                        rd_data = mulDiv_out[31:0];
                    end
                endcase
            end
            7'b0010011: begin
                regWrite= 1'b1;
                imm_w[11:0] = inst_w[31:20];
                case (funct3_w)
                    ADDI_FUNC3: begin
                        rd_data = $signed(rs1_data) + $signed(imm_w[11:0]);
                    end
                    SLLI_FUNC3: begin
                        rd_data = $signed(rs1_data) << $signed(imm_w[11:0]);
                    end
                    SRAI_FUNC3: begin
                        rd_data = $signed(rs1_data) >>> $signed(imm_w[11:0]);
                    end
                    SLTI_FUNC3: begin  
                        rd_data = ($signed(rs1_data) < $signed(imm_w[11:0]))?32'd1:32'd0;                                 
                    end
                endcase
            end
            7'b1100011: begin
                branch_control = 1'b1;
                imm_w[12:0] = {inst_w[31], inst_w[7], inst_w[30:25], inst_w[11:8], 1'b0};
                case (funct3_w)
                    BEQ_FUNC3: begin  
                        condition = (rs1_data == rs2_data)?1'b1:1'b0;             
                    end
                    BGE_FUNC3: begin
                        condition = ($signed(rs1_data) >= $signed (rs2_data))?1'b1:1'b0;
                    end
                    BNE_FUNC3: begin
                        condition = (rs1_data != rs2_data)?1'b1:1'b0;      
                    end
                    BLT_FUNC3: begin
                        condition = ($signed(rs1_data) < $signed (rs2_data))?1'b1:1'b0;
                    end
                endcase
            end
            LW: begin
                mem_cen = (hold)?1'b0:1'b1;
                imm_w[11:0] = inst_w[31:20];
                mem_addr = $signed({1'b0, rs1_data}) + $signed(imm_w[11:0]);
                rd_data = i_DMEM_rdata;
                regWrite= (mem_stall)?1'b0:1'b1;

            end
            SW: begin
                mem_cen = (hold)?1'b0:1'b1;
                mem_wen = (hold)?1'b0:1'b1;
                imm_w[4:0] = inst_w[11:7];
                imm_w[11:5] = inst_w[31:25];
                mem_addr = $signed({1'b0, rs1_data}) + $signed(imm_w[11:0]);
                mem_wdata = rs2_data;
            end
            AUIPC: begin
                regWrite= 1'b1;
                imm_w[31:12] = inst_w[31:12];
                rd_data = PC + imm_w;

            end
            JAL: begin
                imm_w[20:0] = {inst_w[31], inst_w[19:12], inst_w[20], inst_w[30:21], 1'b0};
                regWrite= 1'b1;
                rd_data = PC + 3'd4;
            end
            JALR: begin
                imm_w[11:0] = inst_w[31:20];
                regWrite= 1'b1;
                rd_data = PC + 3'd4;
            end
            ECALL: begin
                // $display("System Call for Finish!!!");
            end
        endcase
    end
    // end


    // -------------------------- Handle PC -----------------------------
    always@(*) begin
        PC_nxt = PC + 3'd4;
        if(op_code_w == JALR) begin
            PC_nxt = $signed({1'b0, rs1_data}) + $signed(imm_w[11:0]);
        end
        else if (op_code_w == JAL) begin
            PC_nxt = $signed({1'b0, PC}) + $signed(imm_w[20:0]);
        end
        else if(jump) begin
            PC_nxt = $signed({1'b0, PC}) + $signed(imm_w[12:0]);
        end
        else if (mem_stall) begin
            PC_nxt = PC;
        end
        else if (op_code_w == 7'b0110011 && 
        ({funct7_w, funct3_w} == {MUL_FUNC7, MUL_FUNC3} && !mulDiv_done)) begin
            PC_nxt = PC;
        end
        else if (op_code_w == ECALL) begin
            PC_nxt = PC;
        end
        else begin
            PC_nxt = PC + 3'd4;
        end
    end

    // FSM
    always @(*) begin
        state_w = state_r;
        finish_nxt = 1'b0;
        case (state_r)
            S_IDLE: begin
                if (op_code_w == ECALL) begin
                    finish_nxt = 1'b1;
                end
                else if (op_code_w == 7'b0110011 && 
                ({funct7_w, funct3_w} == {MUL_FUNC7, MUL_FUNC3}))begin
                    state_w = S_EXEC_MULDIV;
                end
                else begin
                    state_w = S_EXEC;
                end
            end
            S_EXEC: begin
                if (op_code_w == ECALL) begin
                    finish_nxt = 1'b1;
                end
                else if (op_code_w == 7'b0110011 && 
                ({funct7_w, funct3_w} == {MUL_FUNC7, MUL_FUNC3}))begin
                    state_w = S_EXEC_MULDIV;
                end
                else begin
                    state_w = S_EXEC;
                end
            end
            S_EXEC_MULDIV: begin
                state_w = (mulDiv_done) ? S_EXEC : S_EXEC_MULDIV;
            end 
        endcase
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            PC          <= 32'h00010000; // Do not modify this value!!!
            state_r     <= S_IDLE;
            finish      <= 0;
            hold        <= 0;
        end
        else begin
            PC          <= PC_nxt;
            state_r     <= state_w;
            finish      <= finish_nxt;
            hold        <= (mem_stall)?1'b1:1'b0;
        end
    end
endmodule

module Reg_file(i_clk, i_rst_n, wen, rs1, rs2, rd, wdata, rdata1, rdata2);
   
    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth
    
    input i_clk, i_rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] wdata;
    input [addr_width-1:0] rs1, rs2, rd;

    output [BITS-1:0] rdata1, rdata2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign rdata1 = mem[rs1];
    assign rdata2 = mem[rs2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (rd == i)) ? wdata : mem[i];
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            mem[0] <= 0; // x0 = 0
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0; // x0 = 0
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end       
    end
endmodule

module MULDIV_unit(i_clk, i_rst_n, i_valid, i_inst, i_A, i_B, o_data, o_done);
    input                       i_clk;   // clock
    input                       i_rst_n; // reset

    input                       i_valid; // input valid signal
    input [31 : 0]      i_A;     // input operand A
    input [31 : 0]      i_B;     // input operand B
    input [         2 : 0]      i_inst;  // instruction

    output [63 : 0]   o_data;  // output value
    output                      o_done;   // output valid signal

    // Todo: HW2
    // Definition of states
    localparam S_IDLE = 4'd0;
    localparam S_ADD  = 4'd1;
    localparam S_SUB  = 4'd2;
    localparam S_AND  = 4'd3;
    localparam S_OR   = 4'd4;
    localparam S_SLT  = 4'd5;
    localparam S_SRA  = 4'd6;
    localparam S_MUL  = 4'd7;
    localparam S_DIV  = 4'd8;
    localparam S_OUT  = 4'd9;

    // Wires & Regs
    // Todo
    reg  [4:0] counter, counter_nxt;
    reg  [63:0] sh_reg, sh_reg_nxt;
    reg  [32:0] alu_out;  // it's not a real register, it's wire!
    reg         dividend_flag;  // it's not a real register, it's wire!
    reg         done, done_nxt;
    // state
    reg  [3: 0] state, state_nxt; // remember to expand the bit width if you want to add more states!

    // load input
    reg  [  31: 0] operand_a, operand_a_nxt;
    reg  [  31: 0] operand_b, operand_b_nxt;
    reg  [         2: 0] inst, inst_nxt;

    // Wire Assignments
    // Todo
    assign o_data = sh_reg;
    assign o_done = done;
    
    // Always Combination
    // load input
    always @(*) begin
        if (i_valid) begin
            operand_a_nxt = i_A;
            operand_b_nxt = i_B;
            inst_nxt      = i_inst;
        end
        else begin
            operand_a_nxt = operand_a;
            operand_b_nxt = operand_b;
            inst_nxt      = inst;
        end
    end
    // Todo: FSM
    always @(*) begin
        case(state)
            S_IDLE: begin
                if(i_valid) begin
                    case(inst_nxt)
                        3'd0: state_nxt = S_ADD;
                        3'd1: state_nxt = S_SUB;
                        3'd2: state_nxt = S_AND;
                        3'd3: state_nxt = S_OR;
                        3'd4: state_nxt = S_SLT;
                        3'd5: state_nxt = S_SRA;
                        3'd6: state_nxt = S_MUL;
                        3'd7: state_nxt = S_DIV;
                        default: state_nxt = S_IDLE;
                    endcase
                end
                else state_nxt = S_IDLE;
            end
            S_ADD: state_nxt = S_OUT;
            S_SUB: state_nxt = S_OUT;
            S_AND: state_nxt = S_OUT;
            S_OR: state_nxt = S_OUT;
            S_SLT: state_nxt = S_OUT;
            S_SRA: state_nxt = S_OUT;
            S_MUL: state_nxt = (counter == 5'd31)?S_OUT:S_MUL;
            S_DIV: state_nxt = (counter == 5'd31)?S_OUT:S_DIV;
            S_OUT: state_nxt = S_IDLE;
            default : state_nxt = state;
        endcase
    end
    // Todo: Counter
    always @(*) begin
        if(state == S_MUL || state == S_DIV) begin
            counter_nxt = counter + 1;
        end
        else counter_nxt = 0;
    end

    // Todo: ALU output
    always @(*) begin
        alu_out = 0;
        dividend_flag = 0;
        case(state)
            S_ADD: begin
                alu_out = {operand_a_nxt[31], operand_a_nxt} + {operand_b_nxt[31], operand_b_nxt};
                alu_out = (~alu_out[32] & alu_out[31])? // + overflow
                {2'b00, {31{1'b1}}}:(alu_out[32] & ~alu_out[31])? // - underflow
                {2'b11, {31{1'b0}}}:alu_out[31:0]; // no overflow
            end
            S_SUB: begin
                alu_out = {operand_a_nxt[31], operand_a_nxt} + {~operand_b_nxt[31], ((~operand_b_nxt) + 1'd1)};
                alu_out = (~alu_out[32] & alu_out[31])? // + overflow
                {2'b00, {31{1'b1}}}:(alu_out[32] & ~alu_out[31])? // - overflow
                {2'b11, {31{1'b0}}}:alu_out[31:0]; // no overflow
            end
            S_AND: begin
                alu_out = operand_a_nxt & operand_b_nxt;
            end
            S_OR: begin
                alu_out = operand_a_nxt | operand_b_nxt;
            end
            S_SLT: begin
                alu_out = (operand_a_nxt[31] & ~operand_b_nxt[31])?1'd1: // a(-) < b(+)
                (~operand_a_nxt[31] & operand_b_nxt[31])?1'd0: // a(+) > b(-)
                operand_a_nxt < operand_b_nxt; // a, b have same sign
            end
            S_SRA: begin
                if (operand_b_nxt > 5'd31) begin
                    alu_out = {32{operand_a_nxt[31]}}; // right shift all bits
                end else begin
                    alu_out = ({32{operand_a_nxt[31]}} << (32 - operand_b_nxt))
                    + (operand_a_nxt >> operand_b_nxt);     
                end
            end
            S_MUL: begin
                if(sh_reg[0] == 1) begin
                    alu_out = sh_reg[63:32] + operand_b_nxt;
                end
                else begin
                    alu_out = sh_reg[63:32];
                end
            end
            S_DIV: begin
                // if remainder goes < 0, add divisor back
                dividend_flag = (sh_reg[63:32] >= operand_b_nxt);
                if(dividend_flag) begin
                    alu_out = sh_reg[63:32] - operand_b_nxt;
                end 
                else begin
                    alu_out = sh_reg[63:32];
                end
            end
        endcase
    end
    
    // Todo : Shift register
    always @(*) begin
        case(state)
            S_IDLE: begin
                if(!i_valid) sh_reg_nxt = 0; 
                else begin
                    if(inst_nxt == 3'd7)begin
                        sh_reg_nxt = {{31{1'b0}}, i_A, {1'b0}}; 
                    end
                    else begin
                        sh_reg_nxt = {{32{1'b0}}, i_A};
                    end
                end
            end
            S_ADD: begin
                sh_reg_nxt = {32'b0, alu_out[31:0]};
            end
            S_SUB: begin
                sh_reg_nxt = {32'b0, alu_out[31:0]};
            end
            S_AND: begin
                sh_reg_nxt = {32'b0, alu_out[31:0]};
            end
            S_OR: begin
                sh_reg_nxt = {32'b0, alu_out[31:0]};
            end
            S_SLT: begin
                sh_reg_nxt = {32'b0, alu_out[31:0]};
            end
            S_SRA: begin
                sh_reg_nxt = {32'b0, alu_out[31:0]};
            end
            S_MUL: begin
                sh_reg_nxt = {alu_out, sh_reg[31:1]};
            end
            S_DIV: begin
                if(counter == 5'd31)begin
                    if(dividend_flag)begin
                        sh_reg_nxt = {alu_out[31:0], sh_reg[30:0], {1'b1}};
                    end
                    else begin
                        sh_reg_nxt = {alu_out[31:0], sh_reg[30:0], {1'b0}};
                    end
                end
                else begin
                    if(dividend_flag)begin
                        sh_reg_nxt = {alu_out[30:0], sh_reg[31:0], {1'b1}};
                    end
                    else begin
                        sh_reg_nxt = {alu_out[30:0], sh_reg[31:0], {1'b0}};
                    end
                end
            end
            S_OUT: begin
                sh_reg_nxt = sh_reg;
            end
            default: begin
                sh_reg_nxt = sh_reg;
            end
        endcase
    end
    // Todo: output valid signal
    always @(*) begin
        case(state)
            S_IDLE: done_nxt = 0;
            S_ADD: done_nxt = 1;
            S_SUB: done_nxt = 1;
            S_AND: done_nxt = 1;
            S_OR: done_nxt = 1;
            S_SLT: done_nxt = 1;
            S_SRA: done_nxt = 1;
            S_MUL: done_nxt = (counter == 5'd31)?1:0;
            S_DIV: done_nxt = (counter == 5'd31)?1:0;
            S_OUT : done_nxt = 0;
            default : done_nxt = 0;
        endcase
    end

    // Todo: Sequential always block
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state       <= S_IDLE;
            operand_a   <= 0;
            operand_b   <= 0;
            inst        <= 0;
            counter     <= 0;
            done        <= 0;
            sh_reg      <= 0;
        end
        else begin
            state       <= state_nxt;
            operand_a   <= operand_a_nxt;
            operand_b   <= operand_b_nxt;
            inst        <= inst_nxt;
            counter     <= counter_nxt;
            done        <= done_nxt;
            sh_reg      <= sh_reg_nxt;
        end
    end

endmodule

module Cache#(
        parameter BIT_W = 32,
        parameter ADDR_W = 32,
        parameter INDEX_W = 6,
        parameter OFFSET_W = 4,
        parameter TAG_W = 22
    )(
        input i_clk,
        input i_rst_n,
        // processor interface
        input i_proc_cen,
        input i_proc_wen,
        input [ADDR_W-1:0] i_proc_addr,
        input [BIT_W-1:0]  i_proc_wdata,
        output [BIT_W-1:0] o_proc_rdata,
        output o_proc_stall,
        input i_proc_finish,
        output o_cache_finish,
        // memory interface
        output o_mem_cen,
        output o_mem_wen,
        output [ADDR_W-1:0] o_mem_addr,
        output [BIT_W*4-1:0]  o_mem_wdata,
        input [BIT_W*4-1:0] i_mem_rdata,
        input i_mem_stall,
        output o_cache_available,
        // memory data offset
        input  [ADDR_W-1: 0] i_offset
    );
    assign o_cache_available = 0; // change this value to 1 if the cache is implemented

    //------------------------------------------//
    //          default connection              //
    assign o_mem_cen = i_proc_cen;              //
    assign o_mem_wen = i_proc_wen;              //
    assign o_mem_addr = i_proc_addr;            //
    assign o_mem_wdata = i_proc_wdata;          //
    assign o_proc_rdata = i_mem_rdata[0+:BIT_W];//
    assign o_proc_stall = i_mem_stall;          //
    //------------------------------------------//
    //------------------------------------------//
    //          Wires and Registers
    reg done;
    assign o_cache_finish = done;

    always @(posedge i_proc_finish) 
    begin
        done = 1;
    end
endmodule