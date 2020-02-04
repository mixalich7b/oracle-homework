create or replace package translit_pack
is
  
  function to_translit(p_input in varchar2)
    return varchar2;

end;
/
