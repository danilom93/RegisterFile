library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;
use work.functions.all;

entity register_file is
 generic ( nBitsData : integer := 64;
           nBitsAddr : integer := 5
          );
 port (   CLK: 		IN std_logic;
          RESET: 	IN std_logic;
	      ENABLE: 	IN std_logic;
	      RD1: 		IN std_logic;
	      RD2: 		IN std_logic;
	      WR: 		IN std_logic;
	      ADD_WR: 	IN std_logic_vector(nBitsAddr-1 downto 0);
	      ADD_RD1: 	IN std_logic_vector(nBitsAddr-1 downto 0);
	      ADD_RD2: 	IN std_logic_vector(nBitsAddr-1 downto 0);
	      DATAIN: 	IN std_logic_vector(nBitsData-1 downto 0);
          OUT1: 	OUT std_logic_vector(nBitsData-1 downto 0);
	      OUT2: 	OUT std_logic_vector(nBitsData-1 downto 0)
	   );
end register_file;

architecture A of register_file is

   -- suggested structures
   subtype REG_ADDR is natural range 0 to (2**nBitsAddr)-1; -- using natural type
   type REG_ARRAY is array(REG_ADDR) of std_logic_vector(nBitsData-1 downto 0);
   signal REGISTERS : REG_ARRAY;

begin

    process(CLK) begin

    	if rising_edge(CLK) then
    		if RESET = '1' then

    			REGISTERS <= (others => (others => '0'));

    		elsif ENABLE = '1' then

                if RD1 = '1' then

    				OUT1 <= REGISTERS(to_integer(unsigned(ADD_RD1)));
                else

                    OUT1 <= (others => 'Z');
    			end if;

    			if RD2 = '1' then

    				OUT2 <= REGISTERS(to_integer(unsigned(ADD_RD2)));
                else

                    OUT2 <= (others => 'Z');
    			end if;

    			if WR = '1' then

    				REGISTERS(to_integer(unsigned(ADD_WR))) <= DATAIN;

                    -- bypass the register file if write and read occur simultaneous at the same address
                    if (RD1 = '1') and (ADD_WR = ADD_RD1) then

                        OUT1 <= DATAIN;
                    end if;

                    -- bypass the register file if write and read occur simultaneous at the same address
                    if (RD2 = '1') and (ADD_WR = ADD_RD2) then

                        OUT2 <= DATAIN;
                    end if;

    			end if;
    		else

    			OUT1 <= (others => 'Z');
    			OUT2 <= (others => 'Z');
        	end if;
    	end if;
    end process;
end A;

configuration CFG_RF_BEH of register_file is
  for A
  end for;
end configuration;
