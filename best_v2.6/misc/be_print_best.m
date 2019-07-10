function be_print_best(OPTIONS)

% This option is updated along with the code
VERSION     =   OPTIONS.mandatory.version;

    version = ['BEst (version ' VERSION ') ' date];
    fprintf('\n\n\n');
    fprintf('\n\t%s', version);
    fprintf('\n\t%s', 'Brain Entropy in space and time');
    fprintf('\n\t%s', 'Credit: PhysNum - Centre de Recherches Mathematiques (U. of M., Montreal)');
    fprintf('\n\t%s', 'LATIS (ETS, Montreal) and MultiFunkImLab (McGill, Montreal)');
    fprintf('\n\t%s', 'e-mail: latislab@gmail.com');
    fprintf('\n');
return