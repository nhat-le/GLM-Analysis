%% Load the data
clear all;

full_load = 0;
source = 'Z:\CheetahData\Pavarrotti mouse\Pavarrotti Mouse\Session 1\';
file = [source '2017-01-23_15-36-21_STRFMeanSpike.mat'];


if full_load
    load(file);

    % Save only the variables we need
%     save(file_short, 'num_seq', 'Lstim', 'unit1', 'unit2', 'unit3', 'unit4', ...
%         'unit5', 'unit6', 'unit7', 'unit8', ...
%         'unit9', 'unit10', 'unit11', 'unit12', ...
%         'unit13', 'unit14', 'unit15', 'unit16', ...
%         'unit17', 'unit18', 'unit19', 'unit20', ...
%         'unit21', 'unit22', 'unit23', 'unit24', ...
%         'unit25', 'unit26', 'unit27', 'unit28', ...
%         'unit29');
else
    load(file, 'num_seq', 'Lstim', 'numUnits',...
        'unit1', 'unit2', 'unit3', 'unit4', ...
        'unit5', 'unit6', 'unit7', 'unit8', ...
        'unit9', 'unit10', 'unit11', 'unit12', ...
        'unit13', 'unit14', 'unit15', 'unit16', ...
        'unit17', 'unit18', 'unit19', 'unit20', ...
        'unit21', 'unit22', 'unit23', 'unit24', ...
        'unit25', 'unit26', 'unit27', 'unit28', ...
        'unit29');
end

%% Figuring out which unit is MGB/A1
% num_seq: number of the channels
% unit1, unit2,... encode spike times
% Lstim.start_time encodes start times, duration is always 1s
% numUnits: auditory-responsive units

MGB_channels = 1:9;
A1_channels = 10:18;

% Define which unit is MGB and which is A1
responsive_only = 1;

% if responsive_only
%     % unit is MGB or A1 && is auditory-responsive
%     MGB_units = numUnits(numUnits <= 19);
%     A1_units = numUnits(numUnits > 19);
% else
%     % TODO: Hard coded for now...
%     MGB_units = 1:19;
%     A1_units = 20:29;
% end

MGB_units = [1, 3, 7, 14, 18, 17, 10, 4, 2];
A1_units = 28;

% Define start and end of 'trials'
%end_id = 594; % decrease in time from t = 594 to 595...
ntrials = 100;
start_times = Lstim.start_time(1:ntrials);
end_times = Lstim.start_time(1:ntrials) + 1;
deadline = Lstim.start_time(2:ntrials+1);

% Add random jitter
jitter = rand(1, ntrials) * 0;
start_times = start_times - jitter;
end_times = end_times - jitter;

% Define edges
edges = [start_times, end_times];
edges = sort(edges);

%% Start compiling units
glmtrial = struct;

num_units = size(num_seq, 1);
unit_names = {};
var_names = {};

numMD = 1;
numPFC = 1;

for unit_id = 1 : num_units
    % Add new unit if unit_id is in MGB_units or A1_units
    if ismember(unit_id, MGB_units) %MGB unit
        var_names = [var_names {['unit' num2str(numMD)]}];
        unit_names = [unit_names {['MDUnit' num2str(numMD)]}];
        numMD = numMD + 1;
    elseif ismember(unit_id, A1_units) %A1 unit
        var_names = [var_names {['unit' num2str(numPFC)]}];
        unit_names = [unit_names {['PFCUnit' num2str(numPFC)]}];
        numPFC = numPFC + 1;
    end
end

num_responsive = numel(MGB_units) + numel(A1_units);

% Define trial structures
for trial = 1 : ntrials
    
    % Store duration in ms
    glmtrial(trial).duration = 1000 * (end_times(trial) - start_times(trial));
    glmtrial(trial).cueon = 1000;
    glmtrial(trial).cueoff = 2000;
    
 
    glmtrial(trial).cueon = 1000;
    glmtrial(trial).cueoff = 2000;
    glmtrial(trial).context = 1;
    glmtrial(trial).vision = 1;
    glmtrial(trial).audition = 1;
    glmtrial(trial).lowpasscue = 1;
    glmtrial(trial).highpasscue = 1;
    
    switch floor((trial - 1) / 25)
        case 0
            glmtrial(trial).R1C1 = 0;
            glmtrial(trial).R1C2 = [];
            glmtrial(trial).R2C1 = [];
            glmtrial(trial).R2C2 = [];
        case 1
            glmtrial(trial).R1C1 = [];
            glmtrial(trial).R1C2 = 0;
            glmtrial(trial).R2C1 = [];
            glmtrial(trial).R2C2 = [];
        case 2
            glmtrial(trial).R1C1 = [];
            glmtrial(trial).R1C2 = [];
            glmtrial(trial).R2C1 = 0;
            glmtrial(trial).R2C2 = [];
        case 3
            glmtrial(trial).R1C1 = [];
            glmtrial(trial).R1C2 = [];
            glmtrial(trial).R2C1 = [];
            glmtrial(trial).R2C2 = 0;
    end
    
    % Store spike timings
    for unit_id = 1 : num_responsive
        % Define variable name and unit name
        var_name = var_names{unit_id};
        unit_name = unit_names{unit_id};
    
        % Extract spikes of unit in the trial and put into glmtrial
        eval(['trial_vals = ' var_name '(' var_name '> start_times(trial) & '...
            var_name '< end_times(trial));']);
        
        % Some assertions just to make sure
        assert(all(trial_vals > start_times(trial)) && ...
            all(trial_vals < deadline(trial)));
        assert(all(trial_vals - start_times(trial) < glmtrial(trial).duration));
        
        glmtrial(trial).(unit_name) = ...
            1000 * (trial_vals - start_times(trial));
    end
end

%% makeGLMnew script

unitOfTime = 'ms';
numMD = 9;
numPFC = 1;

unitOfTime = 'ms'; 
binSize = 1;
nTrials = 100;

for p = 1
    
    clearvars  -except AUC p glmtrial unitOfTime nTrials binSize binfun numMD numPFC
    
    Name = ['PFCUnit' num2str(p)];
    
    binSize = 1;
    
    binfun = @(t)(t==0)+ceil(t/binSize);
%     correct = arrayfun(@(x) glmtrial(x).reward,1:127);
%     glmtrial = glmtrial(find(correct==1));
    
    %% Specify the fields to load
    
    expt = buildGLM.initExperiment(unitOfTime, binSize);
    
    % values = context
    expt = buildGLM.registerValue(expt, 'context', 'Context');
    
    % timings = cue on, cue off
    expt = buildGLM.registerTiming(expt, 'cueon', 'Cue Onset');
    expt = buildGLM.registerTiming(expt, 'cueoff','Cue Offset');
    
    % timings = vision, rule
    % expt = buildGLM.registerTiming(expt, 'vision', 'Attend to Vision Rule');
    % expt = buildGLM.registerTiming(expt, 'audition', 'Attend to Audition Rule');
    
    % rule is value
    expt = buildGLM.registerTiming(expt, 'vision', 'Attend to Vision Rule');
    expt = buildGLM.registerTiming(expt, 'audition', 'Attend to Audition Rule');
    
    % timings = lpf, hpf
    expt = buildGLM.registerTiming(expt, 'lowpasscue', 'Low Pass Filter Cue');
    expt = buildGLM.registerTiming(expt, 'highpasscue', 'High Pass Filter Cue');
    
    % timing = decision
    expt = buildGLM.registerTiming(expt, 'choice', 'Choice Time');
    
    % type = rule / context pair
    expt = buildGLM.registerValue(expt, 'type', 'Trial type');
    
    % type v2
    expt = buildGLM.registerTiming(expt, 'R1C1', 'Rule 1, Context 1');
    expt = buildGLM.registerTiming(expt, 'R2C1', 'Rule 2, Context 1');
    expt = buildGLM.registerTiming(expt, 'R1C2', 'Rule 1, Context 2');
    expt = buildGLM.registerTiming(expt, 'R2C2', 'Rule 2, Context 2');
    
    % spike trains
    for i = 1:numPFC
        expt = buildGLM.registerSpikeTrain(expt, ['PFCUnit' num2str(i)], 'PFC Spike Train');
    end
    for i = 1:numMD
        expt = buildGLM.registerSpikeTrain(expt, ['MDUnit' num2str(i)], 'MD Spike Train');
    end
    
    %% build design spec object and put data in expt
    
    expt.trial = glmtrial;
    dspec = buildGLM.initDesignSpec(expt);
    
    %% trial type
    bs = basisFactory.makeSmoothTemporalBasis('raised cosine', 1000, 15, binfun);
    % bs = basisFactory.makeSmoothTemporalBasis('boxcar', 600, 16, binfun);
    offset = 0;
    dspec = buildGLM.addCovariateTiming(dspec, 'R1C1', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'R2C1', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'R1C2', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'R2C2', [], [], bs, offset);
    
    %% spike history
    % bs = basisFactory.makeSmoothTemporalBasis('boxcar', 24, 12, expt.binfun);
    % dspec = buildGLM.addCovariateSpiketrain(dspec, 'hist', 'sptrain', 'History filter', bs);
    
    %% add MD coupling
    
    for coupleIdx = 1:numMD
        dspec = buildGLM.addCovariateSpiketrain(dspec, ['MDUnit' num2str(coupleIdx)], ['MDUnit' num2str(coupleIdx)], ['Coupling from MD Unit' num2str(coupleIdx)]);
    end
    
    %% build design matrix
    
    % trialIndices = 1:nTrials;
    trialIndices = 1:100
    dm = buildGLM.compileSparseDesignMatrix(dspec, trialIndices);
    
    endTrialIndices = cumsum(binfun([expt.trial(trialIndices).duration]));
    X = dm.X(1:endTrialIndices(5),:);
    mv = max(abs(X), [], 1); mv(isnan(mv)) = 1;
    X = bsxfun(@times, X, 1 ./ mv);
    
    %%
    
    y = buildGLM.getBinnedSpikeTrain(expt, Name,  dm.trialIndices);
    
    %% Do some processing on the design matrix
    dm = buildGLM.removeConstantCols(dm);
    % dm = buildGLM.zscoreDesignMatrix(dm, [colIndices{:}]);
    
    dm = buildGLM.addBiasColumn(dm); % DO NOT ADD THE BIAS TERM IF USING GLMFIT
    
    %% Least squares for initialization
    tic
    wInit = dm.X' * dm.X \ dm.X' * y;
    toc
    
    %% Use matRegress for Poisson regression
    % it requires `fminunc` from MATLAB's optimization toolbox
    
    fnlin = @nlfuns.exp; % inverse link function (a.k.a. nonlinearity)
    lfunc = @(w)(glms.neglog.poisson(w, dm.X, y, fnlin)); % cost/loss function
    
    
    
    opts = optimset('Algorithm', 'trust-region-reflective', ...
        'GradObj', 'on', 'Hessian','on');
    
    [wml, nlogli, exitflag, ostruct, grad, hessian] = fminunc(lfunc, wInit, opts);
    wvar = diag(inv(hessian));
    

    
    %% Visualize
    ws = buildGLM.combineWeights(dm, wml);
    wvar = buildGLM.combineWeights(dm, wvar);
    
    ct = 0;
    for kCov = 5 : 5+numMD-1
        ct = ct+1;
        
        label = dspec.covar(kCov).label;
        figure(1);
        plot(ws.(label).tr, exp(ws.(label).data), 'k'); hold on
        xlim([ 0 50])
        
        drawnow;
        
        xax = find( ws.(label).tr < 50 );
        gain = (ws.(label).data);
        CouplingFilter{p}{ct} = gain;
        AUC{p}(ct) = sum( gain(xax) );
        Range{p}(ct) = range(gain(xax));
        
    end;
end;
