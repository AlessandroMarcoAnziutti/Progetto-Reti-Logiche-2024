library IEEE;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    port(
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_start : in std_logic;
      i_add : in std_logic_vector(15 downto 0);
      i_k : in std_logic_vector(9 downto 0);
      
      o_done : out std_logic;
      
      o_mem_addr : out std_logic_vector(15 downto 0);
      i_mem_data : in std_logic_vector(7 downto 0);
      o_mem_data : out std_logic_vector(7 downto 0);
      o_mem_we : out std_logic;
      o_mem_en : out std_logic
    );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is
    type S is (SS, S0, S1, S2, S3, S4, S5, S6, S7);
    
    signal curr_state : S;
    
    signal is_0: std_logic;
    signal isnot_0 : std_logic;
    signal shift_rst : std_logic;
    signal mem_read : std_logic;
    signal mem_write : std_logic;
    signal cred_write : std_logic;
    signal cred_write_31 : std_logic;
    signal val_controll : std_logic;
    signal update : std_logic;
    signal temp_done : std_logic;
    signal done_controll : std_logic;
    
    signal path : std_logic_vector(1 downto 0);
    signal curr_addr : std_logic_vector(15 downto 0);
    signal curr_val : std_logic_vector(7 downto 0);
    signal curr_cred : std_logic_vector(7 downto 0);
    
    signal prec_val : std_logic_vector(7 downto 0);
    signal prec_cred : std_logic_vector(7 downto 0);
    
begin
    
    fsm : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            curr_state <= SS;
        elsif i_clk'event and i_clk = '1' then
            case curr_state is
                when SS =>
                    if i_start = '0' then
                        curr_state <= SS;
                    elsif i_start = '1' then
                        curr_state <= S0;
                    end if;
                                        
                when S0 =>
                    if i_start = '1' then
                        if temp_done = '0' then
                            curr_state <= S1;
                        else
                            curr_state <= SS;
                        end if;
                    end if;
                 
                when S1 =>
                    if i_start = '1' then
                        curr_state <= S2;
                    end if;
                    
                when S2 =>
                    if i_start = '1' then
                        curr_state <= S3;
                    end if;
                    
                    
                when S3 =>
                    if i_start = '1' then
                        if path = "01" then
                            curr_state <= S7;
                        elsif path = "10" then
                            curr_state <= S5;
                        elsif path = "11" then
                            curr_state <= S4;
                        end if;
                    end if;
                    
                when S4 =>
                    if i_start = '1' then
                        curr_state <= S7;
                    end if;
                    
                when S5 =>
                    if i_start = '1' then
                        curr_state <= S6;
                    end if;
                    
                when S6 =>
                    if i_start = '1' then
                        curr_state <= S7;
                    end if;
                    
                when S7 =>
                    if i_start = '1' then
                        curr_state <= S0;
                    end if;
            end case;
        end if;
    end process;
    
    fsm_lambda : process(curr_state)
    begin
        o_mem_en <= '0';
        o_mem_we <= '0';
        shift_rst <= '0';
        
        val_controll <= '0';
        update <= '0';
        mem_read <= '0';
        mem_write <= '0';
        cred_write <= '0';
        cred_write_31 <= '0';
        temp_done <= '0';
        done_controll <= '0';
        
        path <= "00";
        prec_val <= "00000000";
        prec_cred <= "00000000";
        curr_val <= "00000000";
        curr_cred <= "00000000";
        curr_addr <= i_add;
        
        case curr_state is
            when SS =>
                done_controll <= '1';
            
            when S0 =>
                done_controll <= '0';
                update <= '0';
                
            when S1 =>
                mem_read <= '1';
            
            when S2 =>
                val_controll <= '1';
                mem_read <= '0';

            when S3 =>                
                val_controll <= '0';         
            
            when S4 =>
                mem_write <= '1';
                mem_read <= '1';
                cred_write_31 <= '1';

            when S5 =>
                mem_write <= '1';
                mem_read <= '1';
                                
            when S6 =>
                cred_write <= '1';
                
            when S7 =>
                mem_write <= '0';
                mem_read <= '0';
                cred_write <= '0';
                cred_write_31 <= '0';
                cred_write <= '0';
                update <= '1';

        end case;
    end process;
    
    done_controll_comp: process(i_clk, done_controll)
    begin
        if temp_done = '1' and i_start = '0' then
            temp_done <= '0';
            o_done <= '0';
            prec_val <= "00000000";
            prec_cred <= "00000000";
        end if;
    end process;

    memory_access: process(i_clk, mem_read, mem_write, cred_write)
    begin
        if mem_read = '1' and mem_write = '0' then
            o_mem_en <= '1';
            o_mem_we <= '0';
            o_mem_addr <= curr_addr;
        elsif mem_read = '1' and mem_write = '1' then
            o_mem_we <= '1';
            o_mem_en <= '1';
            if cred_write = '0' and cred_write_31 = '0' then
                o_mem_addr <= curr_addr;
                o_mem_data <= curr_val;
            else
                o_mem_addr <= curr_addr + 1;
                if cred_write = '1' and cred_write_31 = '0' then
                    if prec_cred = "00000000" then
                        o_mem_data <= "00000000";
                        prec_cred <= "00000000";                    
                    else
                        o_mem_data <= prec_cred - 1;
                        prec_cred <= prec_cred - 1;
                    end if;
                elsif cred_write = '0' and cred_write_31 = '1' then
                    o_mem_data <= "00011111";
                    prec_cred <= "00011111";
                end if;
            end if;
        end if;
    end process;
    
    val_controll_comp: process(i_clk, val_controll)
    begin
        curr_val <= i_mem_data;
        if i_mem_data = "00000000" then
            if prec_val = "00000000" and prec_cred = "00000000" then
                path <= "01";
            else
                path <= "11";
            end if;
        else
            path <= "10";
        end if;
    end process;
    
    update_comp: process(i_clk, update)
    begin
        prec_val <= curr_val;
        curr_addr <= curr_addr + 2;
        if curr_addr = ((i_k - 1) + (i_k - 1) + i_add) then -- 2*(k-1)
            o_done <= '1';
            temp_done <= '1';
        end if;
    end process;
    
end architecture;
