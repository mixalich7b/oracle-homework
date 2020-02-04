create or replace package body translit_pack
is

  type t_varchar_map is table of varchar2 index by varchar2;
     g_translit_map t_varchar_map;
  
  function to_translit(p_input in varchar2)
    return varchar2
  is
  begin

    for russian_letter in g_translit_map.first .. g_translit_map.last  loop
      p_input := replace(p_input, russian_letter, g_translit_map(russian_letter));
    end loop;

    return p_input;
  end;

  procedure initialize_lowercase
  is
  begin
   g_translit_map('а') = 'a';
   g_translit_map('б') = 'b';
   g_translit_map('в') = 'v';
   g_translit_map('г') = 'g';
   g_translit_map('д') = 'd';
   g_translit_map('е') = 'e';
   g_translit_map('ё') = 'yo';
   g_translit_map('ж') = 'zh';
   g_translit_map('з') = 'z';
   g_translit_map('и') = 'i';
   g_translit_map('й') = 'j';
   g_translit_map('к') = 'k';
   g_translit_map('л') = 'l';
   g_translit_map('м') = 'm';
   g_translit_map('н') = 'n';
   g_translit_map('о') = 'o';
   g_translit_map('п') = 'p';
   g_translit_map('р') = 'r';
   g_translit_map('с') = 's';
   g_translit_map('т') = 't';
   g_translit_map('у') = 'u';
   g_translit_map('ф') = 'f';
   g_translit_map('х') = 'x';
   g_translit_map('ц') = 'c';
   g_translit_map('ч') = 'ch';
   g_translit_map('ш') = 'sh';
   g_translit_map('щ') = 'shh';
   g_translit_map('ъ') = '``';
   g_translit_map('ы') = 'y\'';
   g_translit_map('ь') = '`';
   g_translit_map('э') = 'e`';
   g_translit_map('ю') = 'yu';
   g_translit_map('я') = 'ya';
  end;

  procedure initialize_uppercase
  is
  begin
   g_translit_map('А') = 'A';
   g_translit_map('Б') = 'B';
   g_translit_map('В') = 'V';
   g_translit_map('Г') = 'G';
   g_translit_map('Д') = 'D';
   g_translit_map('Е') = 'E';
   g_translit_map('Ё') = 'YO';
   g_translit_map('Ж') = 'ZH';
   g_translit_map('З') = 'Z';
   g_translit_map('И') = 'I';
   g_translit_map('Й') = 'J';
   g_translit_map('К') = 'K';
   g_translit_map('Л') = 'L';
   g_translit_map('М') = 'M';
   g_translit_map('Н') = 'N';
   g_translit_map('О') = 'O';
   g_translit_map('П') = 'P';
   g_translit_map('Р') = 'R';
   g_translit_map('С') = 'S';
   g_translit_map('Т') = 'T';
   g_translit_map('У') = 'U';
   g_translit_map('Ф') = 'F';
   g_translit_map('Х') = 'X';
   g_translit_map('Ц') = 'C';
   g_translit_map('Ч') = 'CH';
   g_translit_map('Ш') = 'SH';
   g_translit_map('Щ') = 'SHH';
   g_translit_map('Ъ') = '``';
   g_translit_map('Ы') = 'Y\'';
   g_translit_map('Ь') = '`';
   g_translit_map('Э') = 'E`';
   g_translit_map('Ю') = 'YU';
   g_translit_map('Я') = 'YA';
  end;

begin
  initialize_lowercase;
  initialize_uppercase
end;
/
