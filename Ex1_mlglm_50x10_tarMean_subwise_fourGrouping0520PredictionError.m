%% Load dataset and define variables
% ------------------------------------------------------------------------

%clear all
close all
clc
%
cd('C:\Users\hp\Desktop\JPain revision')
rating = importdata('Ex1dataEx1data.txt');

subID=rating(:,1);
tarGender=rating(:,2);  %target gender coded as female=-1, male=1
subVAS=rating(:,3);     %pain estimation from perceivers, i.e., our subjects
PSPI=rating(:,4);       %pain facial expressiveness from the shoulder pain database
tarVAS=rating(:,5);     %self-reported pain from the shoulder pain database
subGender=rating(:,6);  %subject gender coded as female=-1, male=1

subjids = unique(subID);
nsub = length(subjids); % length(subVAS)/12; Tor edited

% These are for printing output headers
dashes = '----------------------------------------------';
printhdr = @(str) fprintf('%s\n%s\n%s\n', dashes, str, dashes);

%% Create cell arrays for key variables within each subject
% ------------------------------------------------------------------------

sub_subGender=zeros(nsub,1);

for sub_index=1:nsub 
    % tor: using unique(subID) and selecting is a more robust way to do this! This will fail/be inaccurate with missing data
    % see below
    
    sub_start=1+10*(sub_index-1); % all subjects have 10 trials/targets
    sub_tarVAS{sub_index}=tarVAS(sub_start:sub_start+9);
    sub_PSPI{sub_index}=PSPI(sub_start:sub_start+9);
    sub_tarGender{sub_index}=tarGender(sub_start:sub_start+9);
    sub_subVAS{sub_index}=subVAS(sub_start:sub_start+9);
    sub_subGender(sub_index,:)=subGender(sub_start+1);
    
end


for i=1:nsub
    
    PSPI_targender{i}=[sub_PSPI{i} sub_tarGender{i}];
    tarVAS_targender{i}=[sub_tarVAS{i} sub_tarGender{i}];
    PSPI_tarVAS_targender{i}=[sub_PSPI{i} sub_tarVAS{i} sub_tarGender{i}];
    [b dev st]=glmfit([sub_PSPI{i} sub_tarVAS{i}],sub_subVAS{i});
    resid{i}=st.resid; %sub_subVAS controlling for PSPI and tarVAS
    PredictiorError{i}=[sub_subVAS{i}-sub_tarVAS{i}] % Yoni suggested [pain estimate - pain report] = pain expression + patient gender.
end

%% Run ml-glm with cell array variables-LANLAN
%stats=glmfit_multilevel(sub_subVAS, sub_tarGender, sub_subGender,'names',{'Intcpt', 'tarGender'}, 'weighted') %Simple regression of perceiver VAS on target gender without controlling for anything else 
%stats=glmfit_multilevel(sub_subVAS,PSPI_tarVAS_targender,sub_subGender,'names', {'Intcpt','PSPI', 'tarVAS', 'tarGender'}, 'weighted') %Multiple regression of perceiver VAS on target variables, perceiver gender is moderator
%stats=glmfit_multilevel(sub_subVAS,PSPI_targender,sub_subGender,'names', {'Intcpt','PSPI', 'tarGender'}, 'weighted')
%stats=glmfit_multilevel(sub_subVAS,tarVAS_targender,sub_subGender,'names', {'Intcpt','tarVAS', 'tarGender'}, 'weighted')
stats=glmfit_multilevel(PredictiorError, PSPI_targender,sub_subGender,'names', {'Intcpt', 'pspi', 'targender'}, 'weighted')                                        % gender bias in prediction error 

%% Build design matrix for multi-level multiple regression
% within-subject predictors are target gender, pain rating, pain expressiveness (PSPI)
% between-subject predictor is participant/perceiver gender

[X_matrix, Y] = deal(cell(1, nsub));
Lev2Mod = [];

for i = 1:length(subjids)

    wh = subID == subjids(i);  % this is a logical index for which rows belong to subject i
    
    X_matrix{i}(:, 1) = tarVAS(wh);
    %X_matrix{i}(:, 2) = PSPI(wh);
    %X_matrix{i}(:, 1) = PSPI(wh);
    %X_matrix{i}(:, 3) = tarGender(wh);
    X_matrix{i}(:, 2) = tarGender(wh);
    
    Y{i} = subVAS(wh);
    
    Lev2Mod(i, 1) = unique(subGender(wh)); % will return error if all entries are not same for subject i !!
end


%% Run stats models and print output
% ------------------------------------------------------------------------

printhdr('Multiple regression of perceiver VAS on target variables, perceiver gender is moderator');
%stats = glmfit_multilevel(Y, X_matrix, Lev2Mod,'names', {'Intcpt', 'tarVAS' 'PSPI' 'tarGender'}, 'weighted');
stats = glmfit_multilevel(Y, X_matrix, Lev2Mod,'names', {'Intcpt', 'tarVAS' 'tarGender'}, 'weighted');
%stats = glmfit_multilevel(Y, X_matrix, Lev2Mod,'names', {'Intcpt', 'PSPI' 'tarGender'}, 'weighted');
%%
printhdr('Simple regression of perceiver VAS on target gender without controlling for anything else');
stats=glmfit_multilevel(sub_subVAS, sub_tarGender, sub_subGender,'names', {'Intcpt', 'tarGender'}, 'weighted');
stats=glmfit_multilevel(resid, sub_tarGender, sub_subGender,'names', {'Intcpt', 'tarGender'}, 'weighted','plots');% what is this? gender bias controlling for PSPI & tarVAS? 20180504

%% get within subject STE for plotting
% TOR: I'M NOT SURE THE BELOW IS RIGHT.  ACTUALLY, I'M SURE IT'S NOT,
% BECAUSE IT'S BASED ON THE SUBVAS, NOT RESIDUALS.  
% Barplot_columns will make the within STE directly, so my version below
% will make the plot.

% 
% for i=1:length(resid)
%     toPlotGendPos(i,:)=sub_subVAS{i}(sub_tarGender{i}==1)';
%     toPlotGendNeg(i,:)=sub_subVAS{i}(sub_tarGender{i}==-1)';
% end
% 
% 
% within_ste_PosPos=barplot_get_within_ste(toPlotGendPos(sub_subGender==1,:));
% within_ste_PosNeg=barplot_get_within_ste(toPlotGendPos(sub_subGender==-1,:));
% within_ste_NegPos=barplot_get_within_ste(toPlotGendNeg(sub_subGender==1,:));
% within_ste_NegNeg=barplot_get_within_ste(toPlotGendNeg(sub_subGender==-1,:));

%% get within-subject residuals for plotting, and plot

resid_by_tarGender = zeros(nsub, 2);

for i = 1:length(subjids)

    wh = X_matrix{i}(:, 3) > 0;  % this is a logical index for tarGender = 1 for subject i
    
    resid_by_tarGender(i, 1) = mean(resid{i}(wh));  % mean tarGender = 1
    
    wh = X_matrix{i}(:, 3) < 0;  % this is a logical index for tarGender = -1 for subject i
    
    resid_by_tarGender(i, 2) = mean(resid{i}(wh));  % mean tarGender = 1
    
end

%% Plot them

create_figure('Perceiver ratings by target gender, controlling patient pain and PSPI');

barplot_columns(resid_by_tarGender, 'colors', {[1 1 1] [0 0 0]}, 'within', 'nofigure', 'dolines');
set(gca, 'XTickLabel', {'Female' 'Male'})
xlabel('Patient gender');
ylabel('Perceiver VAS, adjusted');

create_figure('PerceiverVAS by target and subj gender, controlling patient pain and PSPI', 1, 2);
subplot(1, 2, 1); % Males? subGender > 0

barplot_columns(resid_by_tarGender(Lev2Mod > 0, :), 'colors', {[1 1 1] [0 0 0]}, 'within', 'nofigure', 'noviolin', 'noind');
set(gca, 'XTickLabel', {'Female' 'Male'})
xlabel('Patient gender');
ylabel('Perceiver VAS, adjusted');
title('subGender > 0')

subplot(1, 2, 2); % Females? subGender < 0

barplot_columns(resid_by_tarGender(Lev2Mod < 0, :), 'colors', {[1 1 1] [0 0 0]}, 'within', 'nofigure', 'noviolin', 'noind');
set(gca, 'XTickLabel', {'Female' 'Male'})
xlabel('Patient gender');
ylabel('Perceiver VAS, adjusted');
title('subGender < 0')
