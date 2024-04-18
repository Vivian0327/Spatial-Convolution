library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Convolution_pkg IS
	CONSTANT i_width  :integer  := 26;
	CONSTANT i_height :integer  := 26;
	CONSTANT k_width  :integer  := 3;
	CONSTANT k_height :integer  := 3;
	SUBTYPE U9  IS INTEGER RANGE 0 TO 2**9-1;
	SUBTYPE S20 IS INTEGER RANGE -524288 TO 524287; 
	SUBTYPE S32 IS INTEGER RANGE -2**31 TO 2**31-1;
	
	type img_memory is array (0 to i_width-1, 0 to i_height-1) of S20;
	type krl_memory is array (0 to k_width-1, 0 to k_height-1) of S20;
	type Conv_img_memory is array (0 to i_width -(k_width-1)-1, 0 to i_height-(k_height-1)-1) of S20;
	TYPE state_list IS (start, load, calc,done);
end;

use work.Convolution_pkg.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity convolution is	 
	port (  clock: in  std_logic;
			    rst: in  std_logic;
		      x_in: in  S20;
		 additions: out S20;
		  multipls: out S20;
		  Cnv: out S20);
end convolution;

architecture Behavioral of convolution is	
	SIGNAL s: state_list;			-- State of system
	Signal out_valid: std_logic;
	SIGNAL Reg_img:img_memory;
	
	---------------Convolution Kernel----------------
	constant krnl: krl_memory := (
				 (1, 2, 1),
				 (2, 1, 2),
				 (1, 2, 1));
	-------------------------------------------------	
	signal Conv_img:Conv_img_memory;			 
		
BEGIN   
    process (clock)
		 variable sum :		S20;
		 variable n_i_width:	U9    := i_width -(k_width-1);
		 variable n_i_height:U9 	:= i_height-(k_height-1);
		 variable r,c : 		U9 	:= 0;
		 variable add,mul:    S20;
	 begin
		if rst = '1' then
			s <= start;
			out_valid <= '0';
		elsif rising_edge(clock)then
			case s is
			when start =>				------------------> Start
				sum := 0;
				add := 0;
				mul := 0;
				Reg_img <= (others=>(others=>0));
				Conv_img<= (others=>(others=>0));
				s <= load;
			when load =>				------------------> Load input image 
				if r < i_width then
					if c < i_height then
						Reg_img(r,c) <= x_in;
						c := c +1;
					else
						c := 0;
						r := r + 1;
					end if;
				else
					r := 0;
					s <= calc;
				end if;
			when calc =>				------------------> Calulate the convolution
				for y in 0 to (n_i_height-1) loop
					for x in 0 to (n_i_width-1) loop
						sum :=0;
						for k_r in 0 to (k_height-1) loop
							for k_c in 0 to (k_width-1) loop
								sum := sum + Reg_img((y+k_r),(x+k_c)) * krnl(k_r,k_c);
								add := add + 1;
								mul := mul + 1;
							end loop;
						end loop;
						Conv_img(x,y) <= sum;
					end loop;
				end loop;
				s <= done;
				out_valid <= '1';
			when done =>			--------------------> Output the result
				if out_valid = '1' then
					if r < i_width-2 then
						if c < i_height-2 then
							Cnv <= Conv_img(r,c);
							c := c +1;
						else
							c := 0;
							r := r + 1;
						end if;
					else
						r := 0;
						additions <= add;
						multipls <= mul;
						s <= start;
					end if;
				end if;
			end case;
		end if;
    end process;
end Behavioral;