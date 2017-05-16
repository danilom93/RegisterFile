library ieee;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.functions.all;
use work.constants.all;

entity controUnit is

    generic (
        -- Number of windows
        f_windows                                   : integer := f_windows_const;
        -- Number of windows binary
        size_windows                                : integer := size_windows_const
    );

    port (
        clock                                       : in std_logic;
        reset                                       : in std_logic;
        enable                                      : in std_logic;
        call                                        : in std_logic;
        ret                                         : in std_logic;
        -- mmu_done is managed by the Memory Management Unit, it is risen by the MMU when
        -- an operation of spill or fill is completed, so if mmu_done is high the register file
        -- can restart to work normally because the transactions with the memory are completed.
        -- Note that in a real implementation more signal could be needded between the MMU and the register file
        mmu_done                                    : in std_logic;
        -- If the fill signal is high, the MMU should perform a POP to refill the register file
        fill                                        : out std_logic;
        -- If the sfill signal is high, the MMU should perform a PUSH because the register file is full
        spill                                       : out std_logic;
        -- cwp_out is used by the addressesGenerator module to compute the physical addresses
        cwp_out                                     : out std_logic_vector(size_windows-1 downto 0)
    );
end entity;

architecture behavioral of controUnit is

    signal cwp                                      : std_logic_vector(size_windows-1 downto 0);
    signal swp                                      : std_logic_vector(size_windows-1 downto 0);
    signal canSave                                  : std_logic_vector(size_windows-1 downto 0);
    signal canRestore                               : std_logic_vector(size_windows-1 downto 0);

    type stateType is (sReset, sWork, sCall, sReturn, sSpill, sFill);
    signal currentState                             : stateType;
    signal nextState                                : stateType;
begin

    -- Synchronous process used to manage the FSM
    syn_proc                                        : process(clock)
    begin
        if (rising_edge(clock)) then

            currentState <= nextState;
        end if;
    end process;

    -- Asynchronous process to get which will be the nex stare of the FSM
    cu_proc                                         : process(reset, enable, call, ret, mmu_done)

        variable cwp_var                            : integer range 0 to f_windows;
        variable swp_var                            : integer range 0 to f_windows;

        begin
            -- If the module is enabled
            if (enable = '1') then

                -- If the signal reset is high I have to perform a reset
                if(reset = '1') then

                    nextState <= sReset;
                else

                    cwp_var                         := to_integer(unsigned(cwp));
                    swp_var                         := to_integer(unsigned(swp));

                    case(currentState) is

                        when sReset =>
                            -- Reset state
                            cwp <= std_logic_vector(to_unsigned(f_windows, cwp'length)) - 1;
                            swp <= (others => '0');
                            canRestore <= (others => '0');
                            canSave <= std_logic_vector(to_unsigned(f_windows, canSave'length));
							fill <= '0';
							spill <= '0';
							nextState <= sWork;

                        when sWork =>

                            -- Normal work state
                            if(call = '1') then

                                -- If a call happens
                                canRestore <= canRestore + 1;
                                canSave <= canSave - 1;
                                cwp_var   := cwp_var + 1;
								if(cwp_var = f_windows) then

                                    cwp_var := 0;
                                end if;
                                cwp <= std_logic_vector(to_unsigned(cwp_var, cwp'length));
                                nextState <= sCall;
                            elsif(ret = '1') then

                                -- If a return happens
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

                            -- Call state
                            if(canSave = (canSave'range => '0')) then

                                -- If canSave is equal to zero, a spill operation will be perform
                                spill <= '1';
								swp_var := swp_var + 1;
								if(swp_var = f_windows) then

                                    swp_var := 0;
                                end if;
                                swp <= std_logic_vector(to_unsigned(swp_var, swp'length));
                                canSave <= canSave + 1;
                                canRestore <= canRestore - 1;
                                nextState <= sSpill;
                            else

                                nextState <= sWork;
                            end if;
                        when sReturn =>

                            -- Return state
                            if(canRestore = (canRestore'range => '0')) then

                                -- If canRestore is equal to zero, a fill operation will be perform
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

                            -- Spill state
                            if(mmu_done = '1') then

                                -- if the mmu has completed the spill operation the register file
                                -- can return to its normal work mode
                                spill <= '0';
                                nextState <= sWork;
                            else

                                nextState <= sSpill;
                            end if;
                        when sFill =>

                            -- Fill state
                            if(mmu_done = '1') then

                                -- if the mmu has completed the fill operation the register file
                                -- can return to its normal work mode
								fill <= '0';
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

        -- cwp_out will be used by the addressesGenerator to compute the physical addresses
        cwp_out <= cwp;
end architecture;
