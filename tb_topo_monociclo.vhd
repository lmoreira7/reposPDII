library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tb_topo_monociclo is
end entity;

architecture behavior of tb_topo_monociclo is
	
	component topo_monociclo is
		
		port(
		
			clock : in std_logic;
			reset : in std_logic
	
		);
	
	end component;
	
	signal clock_sg : std_logic := '0';
	signal reset_sg : std_logic := '1';
	
	begin
		
		inst_top : topo_monociclo
			
			port map(
				
				clock => clock_sg,
				reset => reset_sg
				
			);
			
		clock_sg <= not clock_sg after 5 ps;
		
		process
			
			begin
				
				wait for 2 ps;
					
					reset_sg <= '0';
				
				wait;
				
		end process;
end behavior;