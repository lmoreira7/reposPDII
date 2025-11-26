library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity monociclo is
	
	port (
		
		clock : in std_logic;
		reset : in std_logic;
		aluSrc : in std_logic;
		regDst : in std_logic;
		aluControl : in std_logic_vector(1 downto 0);
		memToReg : in std_logic;
		memWrite : in std_logic;
		memRead : in std_logic;
		regWrite : in std_logic;
		branch : in std_logic;
		opcode : out std_logic_vector(3 downto 0)
		
	);
	
end entity;


architecture behavior of monociclo is
	
	
	signal programCounter : std_logic_vector(7 downto 0);
	
	-------------- MEMORIA DE INSTRUÇÃO ----------------
	
	type mem is array(integer range 0 to 255) of std_logic_vector(19 downto 0);
	signal memInst : mem;
	signal memInstOut : std_logic_vector(19 downto 0);
	signal op_code : std_logic_vector(3 downto 0);
	signal regOp1 : std_logic_vector(3 downto 0);
	signal regOp2 : std_logic_vector(3 downto 0);
	signal regDest : std_logic_vector(3 downto 0);
	signal desloc : std_logic_vector(7 downto 0);
	signal endereco : std_logic_vector(7 downto 0);
	signal imm_extend : std_logic_vector(15 downto 0);
	signal imm : std_logic_vector(7 downto 0);
	
	------------------------------------------------------
	
	-------------- BANCO DE REGISTRADORES ----------------
	
	type bReg is array(integer range 0 to 15) of std_logic_vector(15 downto 0);
	signal bancoRegs : bReg;
	signal regDestino : std_logic_vector(3 downto 0);
	
	------------------------------------------------------
	
	---------- UNIDADE LÓGICA ARITMÉTICA (ULA) -----------
	
	signal saidaUla : std_logic_vector(15 downto 0);
	signal add : std_logic_vector(15 downto 0);
	signal sub : std_logic_vector(15 downto 0);
	signal mult : std_logic_vector(31 downto 0);
	signal equal : std_logic;
	signal op1 : std_logic_vector(15 downto 0);
	signal op2 : std_logic_vector(15 downto 0);
	
	------------------------------------------------------
	
	--------------- MEMORIA DE DADOS ---------------------
	
	type memData is array(integer range 0 to 255) of std_logic_vector(15 downto 0);
	signal memDados : memData;
	signal memDadosOut : std_logic_vector(15 downto 0);
	
	------------------------------------------------------
	
	begin
		
		--------------- MEMORIA DE INSTRUÇÃO -----------------
		
		memInstOut <= memInst(conv_integer(programCounter));
		
		op_code <= memInstOut(19 downto 16);
		regDest <= memInstOut(15 downto 12);
		regOp1 <= memInstOut(11 downto 8);
		regOp2 <= memInstOut(7 downto 4);
		imm <= memInstOut(7 downto 0);
		imm_extend <= (15 downto 8 => '0') & imm;
		endereco <= memInstOut(7 downto 0);
		desloc <= regDest & memInstOut(3 downto 0);
		
		opcode <= op_code; -- Entrada do Decoder
		
		memInst(0) <= 20x"81005"; -- LDI $1, 5
		memInst(1) <= 20x"82003"; -- LDI $2, 3
		memInst(2) <= 20x"14120"; -- ADD $4, $1, $2
		memInst(3) <= 20x"25410"; -- SUB $5, $4, $1
		memInst(4) <= 20x"93005"; -- ADDI $3, $0, 5
		memInst(5) <= 20x"3A320"; -- MUL $10, $3, $2
		memInst(6) <= 20x"50034"; -- BEQ $0, $3, salta p/ memInst(10)
		memInst(7) <= 20x"B7202"; -- MULI $2, $2, 2
		memInst(8) <= 20x"A3301"; -- SUBI $3, $3, 1
		memInst(9) <= 20x"40006"; -- JMP memInst(6)
		memInst(10) <= 20x"60242"; -- BNE $2, $4, salta p/ memInst(12)
		memInst(11) <= 20x"4000A"; -- JMP memInst(10)
		memInst(12) <= 20x"70205"; -- SW MemDados[5], $2
		memInst(13) <= 20x"0F005"; -- LW $15 MemDados[5]
		
		------------------------------------------------------
		
		-------------- BANCO DE REGISTRADORES ----------------
		
		regDestino <= regOp2 when regDst = '0' else
						  regDest;
		
		
		---------- UNIDADE LÓGICA ARITMÉTICA (ULA) -----------
		
		op1 <= bancoRegs(conv_integer(regOp1));
		
		op2 <= bancoRegs(conv_integer(regOp2)) when aluSrc = '0' else
				 imm_extend;
		
		saidaUla <= add when aluControl = "00" else
						sub when aluControl = "01" else
						mult(15 downto 0);
						
		add <= op1 + op2;
				 
		sub <= op1 - op2;
				 
		mult <= op1 * op2;
				  
		equal <= '1' when op1 = op2 else '0';
	
		------------------------------------------------------
		
		--------------- MEMORIA DE DADOS ---------------------
		
		memDadosOut <= memDados(conv_integer(endereco));
		
		------------------------------------------------------

		
		process(clock, reset)
			
			begin
				
				if reset = '1' then
					
					programCounter <= (others => '0');
					bancoRegs <= (others => (others => '0'));
					memDados <= (others => (others => '0'));
					
				elsif rising_edge(clock) then
				
				-------------------------- INCREMENTO DO PROGRAM COUNTER --------------------------
					
					if (op_code(2) = '0') or (op_code = "0101" and equal = '0') or (op_code = "0110" and equal = '1') or (op_code = "0111") then
						
						programCounter <= programCounter + 1;
					
					else
						
						if op_code = "0100" then -- INCRMENTO DO JUMP
							
							programCounter <= endereco;
						
						else -- INCREMENTO DO BRANCH
							
							programCounter <= programCounter + desloc;
						
						end if;
					end if;
					
				-----------------------------------------------------------------------------------
				
				----------------------------- TIPO R / TIPO I / LW / LWI --------------------------
					
					if op_code(2) = '0' then
					
						if regWrite = '1' then
						
							if memToReg = '1' then
							
								bancoRegs(conv_integer(regDestino)) <= memDados(conv_integer(endereco));
						
							else
						
								bancoRegs(conv_integer(regDestino)) <= saidaUla;
							
							end if;
						end if;
					end if;
					
				----------------------------------------------------------------------------------
				
				--------------------------------- SW ---------------------------------------------
					
					if op_code(2) = '1' then
						
						if memWrite = '1' then
							
							memDados(conv_integer(endereco)) <= saidaUla;
						
						end if;
					end if;
					
				---------------------------------------------------------------------------------
		
				end if;
		end process;

end behavior;