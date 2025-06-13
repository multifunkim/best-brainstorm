function filter = be_get_filter(filter)
%BE_GET_FILTER Summary of this function goes here
%   Detailed explanation goes here
    reel_fil=0;
    be_what_filter_list;
    
    if ~ismember(filter,filter_list)
        if filter(1)=='r'
            disp('!! invalid real filter: we use rdw2')
            filter = 'rdw2';
        elseif filter(1)=='s'
            disp('!! invalid complex filter: we use sdw2')
            filter = 'sdw2';
        else
            disp('!! invalid filter: we use rdw2')
            filter = 'rdw2';
        end
    end
    
    if filter(1)=='r' % Cas reel
        reel_fil = 1;
    end
    
    if reel_fil == 1
        [H0, G0, synF, synG, Jcase] = be_makeqfbreal(filter);
    else
        [var1, var2, H0, G0, Jcase] = be_makeqfb(filter);
    end
    

    filter = struct('filter', filter , 'reel_fil', reel_fil ,'H0',H0 , 'G0', G0,  'Jcase', Jcase);
end

