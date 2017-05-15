library ieee;
use ieee.std_logic_1164.all;
use work.functions.all;

entity controUnit is

    generic (
        -- Number of windows
        f_windows       : integer := 3;
        -- Number of windows binary
        size_windows    : integer := log2(f_windows)
    );

    port (
        clock           : in std_logic;
        reset           : in std_logic;
        enable          : in std_logic;
        call            : in std_logic;
        ret             : in std_logic;
        -- If mmu_done is high, the MMU operation is completed
        mmu_done        : in std_logic;

        fill            : out std_logic;
        spill           : out std_logic;
        cwp_out         : out std_logic_vector(size_windows-1 downto 0);
        swp_out         : out std_logic_vector(size_windows-1 downto 0)
    );
end entity;

architecture behavioral of controUnit is

    signal cwp          : std_logic_vector(size_windows-1 downto 0);
    signal swp          : std_logic_vector(size_windows-1 downto 0);
    signal canSave      : std_logic_vector(size_windows-1 downto 0);
    signal canRestore   : std_logic_vector(size_windows-1 downto 0);

    type stateType is (sReset, sWork, sCall, sReturn, sSpill, sFill);
    signal currentState : stateType;
    signal nextState : stateType;
begin

    syn_proc : process(clock)
    begin
        if (rising_edge(clock)) then

            currentState <= nextState;
        end if;
    end process;


    cu_proc : process(reset, enable, call, ret, mmu_done)

        variable cwp_var : integer range 0 to f_windows;
        variable swp_var : integer range 0 to f_windows;

        begin
            if (enable = '1') then

                if(reset = '1') then

                    nextState <= sReset;
                else

                    cwp_var := to_integer(unsigned(cwp));
                    swp_var := to_integer(unsigned(swp));

                    case(currentState) is

                        when sReset =>

                            cwp <= (others => '0');
                            swp <= (others => '0');
                            canRestore <= (others => '0');
                            canSave <= std_logic_vector(to_unsigned(f_windows, canSave'length));
                            nextState <= sWork;
                        when sWork =>

                            if(call = '1') then

                                canRestore <= canRestore + 1;
                                canSave <= canSave - 1;
                                -- todo
                                cwp_var := (cwp_var + 1) mod f_windows;
                                cwp <= std_logic_vector(to_unsigned(cwp_var, cwp'length));
                                nextState <= sCall;
                            elsif (ret = '1') then

                                canRestore <= canRestore - 1;
                                canSave <= canSave + 1;
                                cwp_var := cwp_var - 1;
                                if (cwp_var > (f_windows - 1)) then

                                    cwp_var := cwp_var - 1;
                                end if;
                                cwp <= std_logic_vector(to_unsigned(cwp_var, cwp'length));
                                nextState <= sReturn;
                            else
                                nextState <= sWork;
                            end if;
                        when sCall =>

                            if(canSave = (canSave'range => '0')) then

                                spill <= '1';
                                swp_var := (swp_var + 1) mod f_windows;
                                swp <= std_logic_vector(to_unsigned(swp_var, swp'length));
                                canSave <= canSave + 1;
                                canRestore <= canRestore - 1;
                                nextState <= sSpill;
                            else
                                nextState <= sWork;
                            end if;
                        when sReturn =>

                            if(canRestore = (canRestore'range => '0')) then

                                fill <= '1';
                                swp_var := swp_var - 1;
                                if(swp_var > (f_windows -1)) then

                                    swp_var := f_windows - 1;
                                end if;
                                swp <= std_logic_vector(to_unsigned(swp_var, swp'length));
                                canRestore <= canRestore + 1;
                                canSave <= canSave - 1;
                                nextState <= sFill;
                            else

                                nextState <= sWork;
                            end if;
                        when sSpill =>
                            spill <= '0';
                            if(mmu_done = '1') then

                                nextState <= sWork;
                            else

                                nextState <= sSpill;
                            end if;
                        when sFill =>
                            fill <= '0';
                            if(mmu_done = '1') then

                                nextState <= sWork;
                            else

                                nextState <= sFill;
                            end if;
                        when others =>
                            nextState <= sReset;
                    end case;
                end if;
            end if;
        end process;

        cwp_out <= cwp;
        swp_out <= swp;
end architecture;
