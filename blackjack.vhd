library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity blackjack is
    port(
        clk : in std_logic;
        hit, stay, start, random_cards : in std_logic;
        cards : in std_logic_vector(3 downto 0);
        
        win, lose, tie : out std_logic;
        card, sum_player_d1, sum_player_d2 : out std_logic_vector(6 downto 0)
    );
end blackjack;

architecture behav of blackjack is
    signal soma_player, soma_dealer, as_player, as_dealer : integer := 0;
    signal game_over : std_logic;
    signal inicio_jogo : std_logic := '1';

    type estado is (inicio, nova_carta_player, nova_carta_dealer, escolha_player, escolha_dealer, decidir_vencedor, empatou, perdeu, venceu);

    signal array_cartas : integer_vector(51 downto 0);
    signal estado_atual : estado;

    -- número aleatório
    signal lfsr : std_logic_vector(5 downto 0) := "000001";
    signal feedback : std_logic;

begin

    feedback <= not(lfsr(5) xor lfsr(4));

    process(clk, start)
    
    -- variáveis auxiliares para controlar a quantidade de ases e soma do jogador e dealer 
    variable aux_soma_player : integer := soma_player;
    variable aux_soma_dealer : integer := soma_dealer;
    variable aux_as_player : integer := as_player;
    variable aux_as_dealer : integer := as_dealer;

    -- variáveis para geração do número aleatório
    
    variable lfsr_i : std_logic_vector(5 downto 0) := lfsr;
    variable int_rand : integer;

    -- variável que receberá a entrada 'cards' ou uma carta aleatória, dependendo do input do usuário
    variable carta_atual : integer := 0;
    
    begin

        if (start='1') then
            estado_atual <= inicio;
            inicio_jogo <= '1';
            game_over <= '0';
            soma_player <= 0;
            soma_dealer <= 0;
            aux_as_dealer := 0;
            aux_as_player := 0;
            aux_soma_dealer := 0;
            aux_soma_player := 0;
            win <= '0';
            lose <= '0';
            tie <= '0';
            card <= "1111111";

            for valor in 0 to 51 loop
                array_cartas(valor) <= 1 + (valor mod 13);
            end loop;

        elsif (clk'event and clk='1' and game_over='0') then

            if (estado_atual=nova_carta_dealer or estado_atual=nova_carta_player) then
                if (random_cards='0') then
                    carta_atual := to_integer(unsigned(cards));
                else
                    -- geração de índice de carta aleatório
                    lfsr_i := lfsr_i(4 downto 0) & feedback;
                    int_rand := to_integer(unsigned(lfsr_i));
                    
                    -- se o índice for maior que 51 (tamanho do vetor de cartas), então subtraimos um valor aleatório do índice
                    if (int_rand>51) then
                        int_rand := int_rand - soma_player - soma_dealer - 12;
                    end if;
                    
                    -- se o índice do vetor já tiver sido usado no presente jogo, outro índice aleatório é gerado
                    if (array_cartas(int_rand)=0) then
                        lfsr_i := lfsr_i(4 downto 0) & feedback;
                        int_rand := to_integer(unsigned(lfsr_i));
                        if (int_rand>51) then
                            int_rand := int_rand - soma_player - soma_dealer - 12;
                        end if;
                    end if;

                    carta_atual := array_cartas(int_rand);
                    array_cartas(int_rand) <= 0;
                    lfsr <= lfsr_i;

                    case carta_atual is
                        when 1 => card <= "0110000";
                        when 2 => card <= "1101101";
                        when 3 => card <= "1111001";
                        when 4 => card <= "0110011";
                        when 5 => card <= "1011011";
                        when 6 => card <= "1011111";
                        when 7 => card <= "1110000";
                        when 8 => card <= "1111111";  
                        when 9 => card <= "1111011";
                        when 10 => card <= "1110111";
                        when 11 => card <= "0011111";
                        when 12 => card <= "0001101";
                        when 13 => card <= "0111101";
                        when others => card <= "1111110";
                    end case;

                    -- considerando que o display acende em nível lógico baixo:
                    -- case carta_atual is
                    --     when 1 => card <= "1001111"; 
                    --     when 2 => card <= "0010010"; 
                    --     when 3 => card <= "0000110"; 
                    --     when 4 => card <= "1001100"; 
                    --     when 5 => card <= "0100100"; 
                    --     when 6 => card <= "0100000"; 
                    --     when 7 => card <= "0001111"; 
                    --     when 8 => card <= "0000000";     
                    --     when 9 => card <= "0000100";
                    --     when 10 => card <= "0001000";
                    --     when 11 => card <= "1100000";
                    --     when 12 => card <= "1110010";
                    --     when 13 => card <= "1000010";
                    --     when others => card <= "0000001";
                    -- end case;
                end if;
            end if;

            case estado_atual is
                when inicio =>
                        estado_atual <= nova_carta_player;
                         
                when nova_carta_player =>

                    if (carta_atual=1) then
                        aux_soma_player := soma_player + 11;
                        aux_as_player := aux_as_player + 1;
                    elsif (carta_atual=11 or carta_atual=12 or carta_atual=13) then
                        aux_soma_player := soma_player + 10;
                    else
                        aux_soma_player := soma_player + carta_atual;
                    end if;

                    if (aux_soma_player>21 and aux_as_player>0) then
                        aux_soma_player := aux_soma_player - 10;
                        aux_as_player := aux_as_player - 1;
                    end if;

                    soma_player <= aux_soma_player;
                    as_player <= aux_as_player;

                    if (inicio_jogo='1') then
                        estado_atual <= nova_carta_dealer;
                    else
                        estado_atual <= escolha_player;
                    end if;
                
                when nova_carta_dealer =>

                    if (carta_atual=1) then
                        aux_soma_dealer := soma_dealer + 11;
                        aux_as_dealer := aux_as_dealer + 1;
                    elsif (carta_atual=11 or carta_atual=12 or carta_atual=13) then
                        aux_soma_dealer := soma_dealer + 10;
                    else
                        aux_soma_dealer := soma_dealer + carta_atual;
                    end if;

                    if (aux_soma_dealer>21 and aux_as_dealer>0) then
                        aux_soma_dealer := aux_soma_dealer - 10;
                        aux_as_dealer := aux_as_dealer - 1;
                    end if;

                    soma_dealer <= aux_soma_dealer;
                    as_dealer <= aux_as_dealer;
                    
                    if (inicio_jogo='0') then
                        estado_atual <= escolha_dealer;
                    elsif (soma_dealer>0) then
                        inicio_jogo <= '0';
                        estado_atual <= escolha_player;
                    else
                        estado_atual <= nova_carta_player;
                    end if;

                when escolha_player =>
                    if (hit='1' and stay='0') then
                        estado_atual <= nova_carta_player;
                    elsif (hit='0' and stay='1') then
                        estado_atual <= escolha_dealer;
                    end if;

                when escolha_dealer => 
                    if (soma_dealer>=17) then
                        estado_atual <= decidir_vencedor;
                    else
                        estado_atual <= nova_carta_dealer;
                    end if;

                when decidir_vencedor =>
                    if (soma_player>soma_dealer) then
                        estado_atual <= venceu;
                    elsif (soma_player=soma_dealer) then
                        estado_atual <= empatou;
                    else
                        estado_atual <= perdeu;
                    end if;
                    
                when others =>
                    game_over <= '1';

            end case;
        end if;

        if (aux_soma_player=21 or (aux_soma_dealer>21 and aux_as_dealer=0)) then
            win <= '1';
            estado_atual <= venceu;
            game_over <= '1';

        elsif (aux_soma_dealer=21 or (aux_soma_player>21 and aux_as_player=0)) then
            lose <= '1';
            estado_atual <= perdeu;
            game_over <= '1';

        elsif (estado_atual=decidir_vencedor) then
            if (aux_soma_player>aux_soma_dealer) then
                win <= '1';
            elsif (aux_soma_dealer>aux_soma_player) then
                lose <= '1';
            else
                tie <= '1';
            end if;
            game_over <= '1';
        end if;


    end process;

    update_Sums : process(soma_player)
        variable unidade : integer;
    begin
        
        if (soma_player<10) then sum_player_d2 <= "1111110";
        elsif (soma_player<20) then sum_player_d2 <= "0110000";
        elsif (soma_player<30) then sum_player_d2 <= "1101101";
        else sum_player_d2 <= "1111001";
        end if;

        unidade := soma_player rem 10;
        case unidade is
            when 0 => sum_player_d1 <= "1111110";
            when 1 => sum_player_d1 <= "0110000";
            when 2 => sum_player_d1 <= "1101101";
            when 3 => sum_player_d1 <= "1111001";
            when 4 => sum_player_d1 <= "0110011";
            when 5 => sum_player_d1 <= "1011011";
            when 6 => sum_player_d1 <= "1011111";
            when 7 => sum_player_d1 <= "1110000";
            when 8 => sum_player_d1 <= "1111111"; 
            when 9 => sum_player_d1 <= "1111011";
            when others => sum_player_d1 <= "1111110";
        end case;

    end process;

end behav;