function [ hInd ] = getHeaderInd( data, searcher )

emsg = "ERROR: getHeaderInd: ";

try
    props = data.Properties.VariableNames;
catch
    emsg = strcat( emsg, "DATA must be Table" );
    error( emsg );
end

hInd = find( strcmp( props, searcher ), 1, 'first' );
if( length( hInd ) < 1 )
    emsg = strcat( emsg, "Ind not found" );
    error( emsg );
end

end