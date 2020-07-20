clear all
close all
clc

cd('C:\Users\hp\Desktop\JPain revision')
rating = importdata('Ex2data.txt');

tarGender=rating(:,1);         %target gender coded as female=-1, male=1
PSPI=rating(:,2)               %pain facial expressiveness from the shoulder pain database 
tarVAS=rating(:,3)             %self-reported pain from the shoulder pain database
subVAS=rating(:,4);            %pain estimation from perceivers, i.e., our subjects
subGender=rating(:,5);         %subject gender coded as female=-1, male=1
sensitivity_MvsF=rating(:,8);
endurance_MvsF=rating(:,9);
willing_MvsF=rating(:,10);
subID=rating(:,11);

subjids = unique(subID);
nsub = length(subjids);  % length(subVAS)/12; Tor edited

% These are for printing output headers
dashes = '----------------------------------------------';
printhdr = @(str) fprintf('%s\n%s\n%s\n', dashes, str, dashes);

%% Create cell arrays for key variables within each subject
sub_subGender=zeros(nsub,1);

for sub_index=1:nsub
 sub_start=1+25*(sub_index-1);
 sub_subVAS{sub_index}=subVAS(sub_start:sub_start+24); 
 sub_PSPI{sub_index}=PSPI(sub_start:sub_start+24);
 sub_tarVAS{sub_index}=tarVAS(sub_start:sub_start+24);
 sub_tarGender{sub_index}=tarGender(sub_start:sub_start+24);
 sub_subGender(sub_index,:)=subGender(sub_start);
 sub_Sensitivity_MvsF(sub_index,:)=sensitivity_MvsF(sub_start:sub_start+24);
 sub_Endurance_MvsF(sub_index,:)=endurance_MvsF(sub_start:sub_start+24);
 sub_Willing_MvsF(sub_index,:)=willing_MvsF(sub_start:sub_start+24); % moderator
 sub_SensitivityDiff=sub_Sensitivity_MvsF(:,1)
 sub_EnduranceDiff=sub_Endurance_MvsF (:,1)
 sub_WillingDiff=sub_Willing_MvsF (:,1)

end

for i=1:nsub
  PSPI_tarVAS_targender{i}=[sub_PSPI{i} sub_tarVAS{i} sub_tarGender{i}];
  tarVAS_targender{i}=[sub_tarVAS{i} sub_tarGender{i}];
  PSPI_targender{i}=[sub_PSPI{i} sub_tarGender{i}];
  [b, dev, st]=glmfit([sub_PSPI{i} sub_tarVAS{i}],sub_subVAS{i});
  resid{i}=st.resid; %sub_subVAS controlling for PSPI and tarVAS 
  PredictiorError{i}=[sub_subVAS{i}-sub_tarVAS{i}] % Yoni suggested [pain estimate - pain report] = pain expression + patient gender.
end

%% Run ml-glm with cell array variables-LANLAN

%stats=glmfit_multilevel(sub_subVAS, sub_tarGender, sub_subGender,'names',{'Intcpt', 'tarGender'}, 'weighted')  %Simple regression of perceiver VAS on target gender without controlling for anything else 
%stats=glmfit_multilevel(sub_subVAS, tarVAS_targender,sub_subGender,'names', {'Intcpt', 'tarVAS', 'targender'}, 'weighted')
%stats=glmfit_multilevel(sub_subVAS, PSPI_targender,sub_subGender,'names', {'Intcpt', 'pspi','targender'}, 'weighted')
%stats=glmfit_multilevel(sub_subVAS, PSPI_tarVAS_targender,sub_subGender,'names', {'Intcpt', 'pspi', 'tarVAS', 'targender'}, 'weighted')                           %gender bias in pain estimates controlling for PSPI & tarVAS, subject gender as moderator
%stats=glmfit_multilevel(sub_subVAS, PSPI_tarVAS_targender,[sub_subGender sub_SensitivityDiff],'names', {'Intcpt', 'pspi', 'tarVAS', 'targender'}, 'weighted')     %gender bias in pain estimates controlling for PSPI & tarVAS, subject gender & sensitivity as moderator
%stats=glmfit_multilevel(sub_subVAS, PSPI_tarVAS_targender,[sub_subGender sub_EnduranceDiff],'names', {'Intcpt', 'pspi', 'tarVAS', 'targender'}, 'weighted')       %gender bias in pain estimates controlling for PSPI & tarVAS, subject gender & endurance as moderator
%stats=glmfit_multilevel(sub_subVAS, PSPI_tarVAS_targender,[sub_subGender sub_WillingDiff],'names', {'Intcpt', 'pspi', 'tarVAS', 'targender'}, 'weighted')         %gender bias in pain estimates controlling for PSPI & tarVAS, subject gender & willingness as moderator
stats=glmfit_multilevel(PredictiorError, PSPI_targender,sub_subGender,'names', {'Intcpt', 'pspi', 'targender'}, 'weighted')                                        % gender bias in prediction error 

%% Build design matrix for multi-level multiple regression
% within-subject predictors are target gender, pain rating, pain expressiveness (PSPI)
% between-subject predictor is participant/perceiver gender

[X_matrix, Y] = deal(cell(1, nsub));
Lev2Mod = [];

for i = 1:length(subjids)

    wh = subID == subjids(i);  % this is a logical index for which rows belong to subject i
    
    X_matrix{i}(:, 1) = tarVAS(wh);
    X_matrix{i}(:, 2) = PSPI(wh);
    X_matrix{i}(:, 3) = tarGender(wh);
    
    Y{i} = subVAS(wh);
    
    Lev2Mod(i, 1) = unique(subGender(wh)); % will return error if all entries are not same for subject i !!
end


%% Run stats models and print output
% ------------------------------------------------------------------------

printhdr('Multiple regression of perceiver VAS on target variables, perceiver gender is moderator');
stats = glmfit_multilevel(Y, X_matrix, Lev2Mod,'names', {'Intcpt', 'tarVAS' 'PSPI' 'tarGender'}, 'weighted');

printhdr('Simple regression of perceiver VAS on target gender without controlling for anything else');
stats=glmfit_multilevel(sub_subVAS, sub_tarGender, [],'names', {'Intcpt', 'tarGender'}, 'weighted');
stats=glmfit_multilevel(resid, sub_tarGender, [],'names', {'Intcpt', 'tarGender'}, 'weighted');


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



