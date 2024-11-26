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
    type S is (S0, S1, S2, S3, S4, S5);    
    signal curr_state, next_state : S;
    
    signal done_con: std_logic;
    signal subbed: std_logic;
    signal temp_done: std_logic;
    signal curr_addr : std_logic_vector(15 downto 0);
    signal path : std_logic_vector(1 downto 0);
    signal curr_val : std_logic_vector(7 downto 0);
    signal curr_cred : std_logic_vector(7 downto 0);
    signal prec_val : std_logic_vector(7 downto 0);
    signal prec_cred : std_logic_vector(7 downto 0);
    
    begin
    
        process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            curr_state <= S0;
        elsif i_rst = '0' and i_clk'event and i_clk = '1' then
            curr_state <= next_state;
        end if;
        
        case curr_state is
            when S0 =>
                if i_start = '0' or temp_done = '1' then
                    o_done <= '0';
                    next_state <= S0;
                else
                    done_con <= '0';
                    subbed <= '0';
                    o_mem_en <= '0';
                    o_mem_we <= '0';
                    o_done <= '0';
                    temp_done <= '0';
                    curr_addr <= i_add;
                    path <= "00";
                    curr_val <= "00000000";
                    curr_cred <= "00000000";
                    prec_val <= "00000000";
                    prec_cred <= "00000000";
                    next_state <= S1;
                end if;
                
            when S1 =>
                if rising_edge(i_clk) then
                    done_con <= '0';
                    subbed <= '0';
                    if temp_done = '1' then
                        next_state <= S0;
                    else
                        o_mem_en <= '1';
                        o_mem_addr <= curr_addr;
                        next_state <= S2;
                    end if;
                end if;
                
            when S2 =>
                if rising_edge(i_clk) then
                    o_mem_en <= '0';
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
                    next_state <= S3;
                end if;
                
            when S3 =>
                if rising_edge(i_clk) then
                    if path = "10" or path = "11" then
                        o_mem_en <= '1';
                        o_mem_we <= '1';
                        if path = "10" then
                            o_mem_addr <= curr_addr + 1;
                            o_mem_data <= "00011111";
                            prec_cred <= "00011111";
                        else
                            o_mem_addr <= curr_addr + 1;
                            if prec_cred = "00000000" then
                                o_mem_data <= "00000000";
                            else
                                if subbed = '0' then
                                    subbed <= '1';
                                    o_mem_data <= prec_cred - 1;
                                    prec_cred <= prec_cred - 1;
                                end if;
                            end if;
                        end if;
                    end if;
                    next_state <= S4;
                end if;
            
            when S4 =>
                if rising_edge(i_clk) then
                    subbed <= '0';
                    if path = "11" then
                        o_mem_addr <= curr_addr;
                        o_mem_data <= prec_val;
                    end if;
                    next_state <= S5;
                end if;
                
            when S5 =>
                if rising_edge(i_clk) then
                    if done_con = '0' then
                        done_con <= '1';
                        if curr_addr = ((i_k-1) + (i_k-1) + i_add) then -- 2*(k-1)
                            temp_done <= '1';
                            o_done <= '1';
                        end if;
                    end if;
                    o_mem_en <= '0';
                    o_mem_we <= '0';
                    if subbed = '0' then
                        subbed <= '1';
                        curr_addr <= curr_addr + 2;
                    end if;
                    if path = "01" then
                        prec_val <= "00000000";
                    elsif path = "10" then
                        prec_val <= curr_val;
                    else
                        prec_val <= prec_val;
                    end if;
                    next_state <= S1;
                end if;
        end case;
    end process;
end architecture;