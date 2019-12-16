
%% specify the file path
behaDir = 'D:\Documents\travellingEchoWaves\Data\TravechoRaw\Beh_data\';          
eegDir  = 'D:\Documents\travellingEchoWaves\Data\TravechoProc\a_processed_data\';
saveDir = 'D:\Documents\travellingEchoWaves\Data\TravechoProc\b_organizedData_EEG_beha_combined_noRemovingICs\';
addpath(genpath('\Program Files\MATLAB\R2018b\eeglab14_1_2b'))% adds the specified folders to the top of the search path

%% Behaviour data acuisition for All subjects
files = dir(behaDir); % Subnumber*1 struct array with fields: name, folder, date,bytes, isdir, datenum
dirFlags = [files.isdir]; %1-folder; 0-file [1 1 1 1 1]
subFolders = files(dirFlags); % exclude non-folder
subFolders(ismember( {subFolders.name}, {'.', '..'})) = [];  %remove . and .. 

%% EEG data acquisition for ALL subjects
allfiles=dir([eegDir '/*.mat']); 
allConditions = [100,200]; % get the conditions to make condition index

for ff = 1:length(allfiles) % loop over the subjects!
    
    % load EEG data for one subject
    preprocFile = allfiles(ff).name; % "1_resamp160_avgreref_epoch.mat"
    disp(['processing' preprocFile])
    load([eegDir preprocFile])
    
    % Beh data for one subject
    dataDir = [behaDir subFolders(ff).name '/']; % data path
    Behfiles=dir([dataDir '/*.mat']); % all beh data for one subject
    
    % EEG data classification
    dynamicEEG   = [];
    staticEEG = [];
    dynamicLum   = [];
    staticLum  = [];   
    
    % loop over the EEG data for one subject      
    for ii = 1:length(ALLEEG)  
        EEG = ALLEEG(ii);
        
        % make a list of condition indices to find the corresponding lum in the behavioral data.
        type = [EEG.event.type]; 
        dynamicIdx  = type == 100; 
        staticIdx = type == 200;        
              
       %% get EEG data and concatenate data over loop for one subject
        dynamicEEGtemp  = EEG.data(:,:,dynamicIdx); % channel(64) * timepoints * trials
        staticEEGtemp = EEG.data(:,:,staticIdx);       
        dynamicEEG  = cat(3, dynamicEEG,  dynamicEEGtemp); % Concatenate arrays along specified dimension
        staticEEG = cat(3, staticEEG, staticEEGtemp); 

       %% get behavioral data and concatenate data over loop for one subject
        behaFile = strcat(dataDir,Behfiles(ii).name);
        load(behaFile);
        
        
        
       %% 不懂不懂不懂~不明白，行为数据到底是如何放置的？？？？   
        % 【问题】在于我使用事先生成的Stimu还是做完实验之后的。母前该问题不是很重要
        % get the lum sequence from the behav data and rearrange them
        % remove NaN and 0 data first
        count_d = 1;
        count_s = 1;
        
        stims=output.stims; startingConditionFlag=output.startingConditionFlag;
        trialsC1=output.trialsC1; trialsC2=output.trialsC2;
        for cc=1:size(stims,2)
            %dynamic luminance
            if (startingConditionFlag==1 && ismember(cc,trialsC1))||(startingConditionFlag==2 && ismember(cc,trialsC2))
                if  (~isnan(sum(stims(:,cc)))) && (~sum(stims(:,cc)) == 0)
                    tempDynlumsmatrix(:,count_d) = stims(:,cc);
                    count_d = count_d + 1;
                end
            %static luminance   
            else 
                if  (~isnan(sum(sum(stims(:,cc))))) && (~sum(sum(stims(:,cc))) == 0)
                    tempStalumsmatrix(:,count_s) = stims(:,cc); % 800 * 150
                    count_s = count_s + 1;
                end
            end
        end

        dynamicLum   = permute(tempDynlumsmatrix,[2 1]);% 150×800
        staticLum  = permute(tempStalumsmatrix,[2 1]);
        
        % 【这是为啥呢】
        clear tempDynlumsmatrix tempStalumsmatrix;  
    end
    channelInfo = {EEG.chanlocs.labels}; % char_{}
    triggers= [EEG.urevent.type]; 
    C = strsplit(preprocFile,'.');
    saveFile = [saveDir C{1} '_lumIncluded.mat'];
    save(saveFile,'dynamicEEG','staticEEG', 'dynamicLum','staticLum', 'channelInfo','triggers');
end




