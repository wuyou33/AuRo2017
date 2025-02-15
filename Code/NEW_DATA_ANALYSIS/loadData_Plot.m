% clear all; clc; close all;

%% THIS SCRIPT IS A COPY OF loadData.m HOWEVER IS MODIFIED TO INCLUDE PLOTTING CAPABILITIES FOR GOAL PROBABILITIES, BUTTON PRESS PATTERNS ETC. 
% DIFFERENT CODE BLOCKS DOES DIFFERENT JOBS. USER BREAK POINTS AT THE
% END/BEGINNING OF DIFFERENT BLOCKS TO OBTAIN THE PLOTS OF INTEREST. 
%%
load('trial_order_testing_8.mat');

subList = {'H2', 'H3', 'H4', 'H5', 'H6', 'H7', 'H8', 'H9'};
total_subjects = length(subList);
trialList = (1:8)';
phases = {'PH1','PH2'};
interfaces = {'J2', 'HA'};
tasks = {'RE','PO'};
assis = {'wo', 'on'};
task_order = {'PO','RE','RE','PO','RE','PO','PO','RE'}; %Phase 1 tasks. 
trials_per_phase = 16;
%%

total_time_all = zeros(trials_per_phase, length(phases), total_subjects);

%user initiated modeswitches =  total_mode_switches - number of assistance
%requests. 
num_assis_req = zeros(trials_per_phase, length(phases), total_subjects); %onlty for trials with 'on' mode 
ar_norm_ts = cell(trials_per_phase, length(phases), total_subjects);
hist_ar_norm_ts = []; %HISTOGRAM OF THE NORMALIZED ASSISTANCE TIMES. TO COMPUTE SKEWNESS OF THE ASSISTANCE TIME REQUEST. 
first_disamb_req = []; %TIME OF FIRST DISAMB REQUEST. 
num_mode_switches = zeros(trials_per_phase, length(phases), total_subjects);
mode_switch_time_stamps = cell(trials_per_phase, length(phases), total_subjects);
current_mode_time_stamps = cell(trials_per_phase, length(phases), total_subjects);
mode_switches_all = cell(trials_per_phase, length(phases), total_subjects);
current_mode_all = cell(trials_per_phase, length(phases), total_subjects);

goal_probabilities_all = cell(trials_per_phase, length(phases), total_subjects);

%cdim and cmode coming from ONLY mode switches
cdim_ar_time_stamps = cell(trials_per_phase, length(phases), total_subjects);
cmode_ar_time_stamps = cell(trials_per_phase, length(phases), total_subjects);
cdim_ar_conf_all = cell(trials_per_phase, length(phases), total_subjects);
cmode_ar_conf_all = cell(trials_per_phase, length(phases), total_subjects);

%FOR ONLY MODE SWITCHES DUE TO ASSIS REQ
assistance_req_time_stamps = cell(trials_per_phase, length(phases), total_subjects);
assistance_req_mode_switch_all = cell(trials_per_phase, length(phases), total_subjects);


%ALPHA TIME SERIES

alpha_all = zeros(trials_per_phase, length(phases), total_subjects);

%%

%% WHICH BUTTON PRESS WAS THE FIRST DISAMB REQUEST. THIS WAS HARDLY USED FOR ANYTHING. 
ha_re_av = 1; %3 -mean
ha_po_av = 2; %4 - mean
j2_re_av = 2; %2 -mean
j2_po_av = 1;

%%


for i=1:total_subjects
    user = subList{i};
    trialId = trialList(i);
    fnames = dir(user);
    numfids = length(fnames);
    for j=3:numfids
        n = fnames(j).name;
        load(n);
        temp = n; n(end-3:end) = []; %remove .mat extension
        if length(n) == 12
            trialnum = str2double(n(end-1:end));
        else
            trialnum = str2double(n(end));
        end
        if strcmp(n(3:5), 'PH1')
            ph = 1;
        elseif strcmp(n(3:5), 'PH2')
            ph = 2;
        end
        subid = str2double(n(2)) - 1; %H1 gets 1 H2 gets 2 and so on and so forth
        total_time_all(trialnum, ph, subid) = total_time;
        
        %alpha's time stamp is shared by all the ones 
        
        alpha(1, :) = []; alpha(:, 2) = alpha(:, 2) - start_time;
        thread_times = alpha(:, 2); %GET TIME STAMPS FOR ALPHA. SHARED BY ALL MESSGAES THAT WAS PUBLISHED FROM THE BLENDING THREAD. 
        
        goal_probabilities(1, :) = [];
        if strcmp(n, 'H7PH2REJ2T5') || strcmp(n, 'H8PH2REHAT5') || strcmp(n, 'H9PH1REJ2T15')
            goal_probabilities(1:2, :) = [];
        end
        if strcmp(n, 'H8PH2REHAT8')
            goal_probabilities(1, :) = [];
        end
        goal_probabilities = [goal_probabilities thread_times(1:size(goal_probabilities, 1))];
        goal_probabilities = trim_data(goal_probabilities, false);
        goal_probabilities_all(trialnum, ph, subid) = {goal_probabilities};
        
        if strcmp(n(6:7), 'RE')
            alpha = trim_data(alpha, false);
%             alpha_all(trialnum, ph, subid) = sum(alpha(:, 1) > 0.0)/length(alpha(:, 1));
            alpha_all(trialnum, ph, subid) = alpha(min(find(alpha(:, 1) > 0)), end)/total_time;
        else
            if ph == 1
                taskid = ph1_trial_mat{trialnum, 4 ,subid};  
            else
                taskid = ph2_trial_mat{trialnum, 4 ,subid};
            end
            if taskid == 1 || taskid == 2
                gmarker = 2;
            elseif taskid == 3 || taskid == 4
                gmarker = 4;
            end
            [m, ind] = max(goal_probabilities(:, 1:end-1), [], 2);
            %find all ind which is equal gmarker. 
            gm_ind = find(ind == gmarker);
            m_gm = m(gm_ind);
            m_gm_max = find(m_gm == max(m_gm)); 
            if isempty(m_gm_max)
                continue;
            end
            m_gm_max = m_gm_max(1);
            seg_break = gm_ind(m_gm_max);
            alpha_seg = alpha(seg_break:end, 1);
            
            %find where gp rise and passes threshold right after the seg
            %break
            tempg = goal_probabilities(seg_break:end, 1:end-1);
            tempg = max(tempg, [], 2);
%             coeff = ones(1, 5)/5;
%             smoothtempg = filter(coeff, 1, tempg); smoothtempg(1:3) = []; smoothtempg = [smoothtempg;smoothtempg(end)*ones(3,1)];
            deltat = min(intersect(find(diff(tempg) > 0), find(tempg > 0.25))); %max goal probability above 0.25 means alpha > 0
            frac = (goal_probabilities(seg_break+deltat, end) - goal_probabilities(seg_break, end))/(goal_probabilities(end, end) - goal_probabilities(seg_break, end));
%             plot(goal_probabilities(:, 1:end-1));
            alpha = trim_data(alpha, false);
            disp(alpha(min(find(alpha(:, 1) > 0)), end)/total_time);
            if alpha(min(find(alpha(:, 1) > 0)), end)/total_time < 0 
                disp(alpha);
            end
            disp(frac);
%             close all;
        end
        
%         close all; figure;
%         plot(goal_probabilities(:, end)/goal_probabilities(end,end), goal_probabilities(:, 1:end-1)); hold on; grid on;  
        
        disp(n);
        %remove 0's and initial mode
        assistance_requested(1, :) = [];
        cdim_conf_disamb(1, :) = [];
        cmode_conf_disamb(1, :) = [];
%         disp(alpha_all(trialnum, ph, subid)
       
        mode_switches(1:2, :) = []; %remove 0 and initial mode;
        current_mode(1:2, :) = []; %remove 0 and initial mode;
        
        if strcmp(n(8:9), 'HA') %fix the double message for headarray. 
            repeated_index = find(diff(current_mode(:, 2) - start_time) < 0.001) + 1;
            current_mode(repeated_index, :) = [];
        end
%         current_mode(:,2) = current_mode(:,2) - start_time;
        num_mode_switches(trialnum, ph, subid) = size(mode_switches,1) - size(assistance_requested, 1); % and assistance requests also triggers mode switch publisher. 
        num_assis_req(trialnum, ph, subid) = size(assistance_requested, 1);
        
        if size(mode_switches, 1) > 0 %if user didn't press any, and there was no assistance, can happen when it is wo and the initial mode happened to be a good one.
            normalized_mode_switch_times = mode_switches(:, end) - start_time;
            normalized_current_mode_times = current_mode(:, end) - start_time;
            normalized_cdim_times = cdim_conf_disamb(:, end) - start_time;
            normalized_cmode_times = cmode_conf_disamb(:, end) - start_time;
            normalized_assistance_times = assistance_requested(:, end) - start_time;
            
             %Identify ONLY those mode switch time stamps that DID NOT come
            %from assistance requested. THese are the ones which are
            %user-initiated mode switches.
            mode_switch_ignore_list = zeros(length(normalized_assistance_times), 1);
            for kk = 1:size(normalized_assistance_times, 1)
                diff_list = normalized_mode_switch_times - normalized_assistance_times(kk);
                diff_list(diff_list < 0) = -999; %make negative really large negative so that when abs is taken does not play a role. 
                mode_switch_ignore_list(kk) = find(abs(diff_list) == min(abs(diff_list)));
            end
            
            if num_mode_switches(trialnum, ph, subid) > 0 %if there are user initiated mode switches
                mode_switch_time_stamps(trialnum, ph, subid) = {normalized_mode_switch_times((setdiff(1:length(normalized_mode_switch_times), mode_switch_ignore_list)))};
                current_mode_time_stamps(trialnum, ph, subid) = {normalized_current_mode_times((setdiff(1:length(normalized_mode_switch_times), mode_switch_ignore_list)))};
                mode_switches_all(trialnum, ph, subid) = {mode_switches(setdiff(1:size(mode_switches,1), mode_switch_ignore_list), 1)};
                current_mode_all(trialnum, ph, subid) = {current_mode(setdiff(1:size(current_mode,1), mode_switch_ignore_list), 1)};
                
                %clean up repetetive user activated mode switches for
                %joystick.
                 if strcmp(n(8:9), 'J2')
                    cm_t = current_mode_time_stamps{trialnum, ph, subid};
                    cm = current_mode_all{trialnum, ph, subid};
                    ms_t = mode_switch_time_stamps{trialnum, ph, subid};
                    ms = mode_switches_all{trialnum, ph, subid}; 
                    if ~isempty(find(diff(cm) == 0))
                        ind_cm = find(diff(cm) == 0);
                        ind_cmt = find(diff(cm_t) < 2);
                        if ~isempty(intersect(ind_cm, ind_cmt))
                            cm(intersect(ind_cm, ind_cmt) + 1,:) = [];
                            cm_t(intersect(ind_cm, ind_cmt) + 1,:) = [];
                            ms(intersect(ind_cm, ind_cmt) + 1,:) = [];
                            ms_t(intersect(ind_cm, ind_cmt) + 1,:) = [];
                            
                            current_mode_all(trialnum, ph, subid) = {cm};
                            current_mode_time_stamps(trialnum, ph, subid) = {cm_t};
                            mode_switches_all(trialnum, ph, subid) = {ms};
                            mode_switch_time_stamps(trialnum, ph, subid) = {ms_t};
                            num_mode_switches(trialnum, ph, subid) = num_mode_switches(trialnum, ph, subid) - length(ind);
                            
                        end
                    end
                 end
% %                 scatter(mode_switch_time_stamps{trialnum, ph, subid}/goal_probabilities(end,end), (i*0.1)*ones(length(mode_switch_time_stamps{trialnum, ph, subid}), 1), 30, 'k', 'filled');
%                 if strcmp(n(8:9), inter) && strcmp(n(6:7), task) %scatter plot for user initiated mode switches. 
%                     scatter(mode_switch_time_stamps{trialnum, ph, subid}/total_time, (i*1)*ones(length(mode_switch_time_stamps{trialnum, ph, subid}), 1), 30, 'k', 'filled', 'MarkerFaceAlpha', 0.5);
%                 end   
            else
                mode_switch_time_stamps(trialnum, ph, subid) = {-1};
                mode_switches_all(trialnum, ph, subid) = {-1};
                current_mode_time_stamps(trialnum, ph, subid) = {-1};
                current_mode_all(trialnum, ph, subid) = {-1};
            end
            
            if num_assis_req(trialnum, ph, subid) > 0
                assistance_req_time_stamps(trialnum, ph, subid) = {normalized_assistance_times};
                assistance_req_mode_switch_all(trialnum, ph, subid) = {mode_switches(mode_switch_ignore_list, 1)};
                cdim_ar_time_stamps(trialnum, ph, subid) = {normalized_cdim_times};
                cmode_ar_time_stamps(trialnum, ph, subid) = {normalized_cmode_times};
                cdim_ar_conf_all(trialnum, ph, subid) = {cdim_conf_disamb(:, 1:end-1)};
                cmode_ar_conf_all(trialnum, ph, subid) = {cmode_conf_disamb(:,1:end-1)};
                total_time_all(trialnum, ph, subid) = total_time_all(trialnum, ph, subid) - 0*length(normalized_assistance_times);
%                 scatter(assistance_req_time_stamps{trialnum, ph, subid}/goal_probabilities(end,end), (i*0.1 + 0.02)*ones(length(assistance_req_time_stamps{trialnum, ph, subid}), 1), 30, 'r', 'filled');
                ar_norm_ts(trialnum, ph, subid) = {assistance_req_time_stamps{trialnum, ph, subid}/total_time};
                
                 %remove duplicate assistance requests for both interfaces
                if ~isempty(diff(normalized_assistance_times))
                    diff_ar_t = diff(normalized_assistance_times);
                    if ~isempty(find(diff_ar_t < 3))
                        ind = find(diff_ar_t < 3) + 1;
                        normalized_assistance_times(ind) = [];
                        ar_ms = assistance_req_mode_switch_all{trialnum, ph, subid};
                        ar_ms(ind) = [];
                        assistance_req_time_stamps(trialnum, ph, subid) = {normalized_assistance_times};
                        assistance_req_mode_switch_all(trialnum, ph, subid) = {ar_ms};
                        num_assis_req(trialnum, ph, subid) = num_assis_req(trialnum, ph, subid) - length(ind); %correct number of assistance request. 
                        ar_norm_ts(trialnum, ph, subid) = {assistance_req_time_stamps{trialnum, ph, subid}/total_time};
                    end
                end
               
                
                
%                 if strcmp(n(8:9), inter) && strcmp(n(6:7), task) %scatter plot for assistance requests. 
%                     scatter(assistance_req_time_stamps{trialnum, ph, subid}/total_time, (i*1 + 0.0)*ones(length(assistance_req_time_stamps{trialnum, ph, subid}), 1), 30, 'r', 'filled');
%                     hist_ar_norm_ts = [hist_ar_norm_ts; ar_norm_ts{trialnum, ph, subid}]; %normalized time stamps for assistance requests.
% %                     ms = mode_switch_time_stamps{trialnum, ph, subid};
% %                     ar = assistance_req_time_stamps{trialnum, ph, subid};
% %                     com = sort([ms;ar]);
% %                     first_disamb_req = [first_disamb_req ; find(com == ar(1))];
%                     
%                 end
                
            else
                assistance_req_time_stamps(trialnum, ph, subid) = {-1};
                assistance_req_mode_switch_all(trialnum, ph, subid) = {-1};
                cdim_ar_time_stamps(trialnum, ph, subid) = {-1};
                cmode_ar_time_stamps(trialnum, ph, subid) = {-1};
                cdim_ar_conf_all(trialnum, ph, subid) = {-1};
                cmode_ar_conf_all(trialnum, ph, subid) = {-1};
                ar_norm_ts(trialnum, ph, subid) = {-1};
            end
        else
                mode_switch_time_stamps(trialnum, ph, subid) = {-1};
                mode_switches_all(trialnum, ph, subid) = {-1};
                assistance_req_time_stamps(trialnum, ph, subid) = {-1};
                assistance_req_mode_switch_all(trialnum, ph, subid) = {-1};
                cdim_ar_time_stamps(trialnum, ph, subid) = {-1};
                cmode_ar_time_stamps(trialnum, ph, subid) = {-1};
                cdim_ar_conf_all(trialnum, ph, subid) = {-1};
                cmode_ar_conf_all(trialnum, ph, subid) = {-1};
                current_mode_time_stamps(trialnum, ph, subid) = {-1};
                current_mode_all(trialnum, ph, subid) = {-1};
                ar_norm_ts(trialnum, ph, subid) = {-1};
        end
        
         
    end
end

%%  FIX DATA POINTS. ALL INVALID ONES ARE GIVEN NEGATIVE VALUES. AT THE END OF PARSE DATA REMOVE THEM. 

%H2

%H3

num_mode_switches(12, 2, 2) = -999;
total_time_all(12,2,2) = -999;
alpha_all(12,2,2) = -999;
num_assis_req(12,2,2) = -999;
%H4
num_mode_switches([9,12],2,3) = -999;
total_time_all([9,12],2,3) = -999;
alpha_all([9,12],2,3) = -999;
num_assis_req([9,12],2,3) = -999;
%H5
num_mode_switches([3,4,11,14, 16],1,4) = -999;
total_time_all([3,4,11,14, 16],1,4) = -999;
alpha_all([3,4,11,14, 16],1,4) = -999;
num_assis_req([3,4,11,14, 16],1,4) = -999;
%H6
%ph1
num_mode_switches(8,1,5) = -999;
total_time_all(8,1,5) = -999;
alpha_all(8,1,5) = -999;
num_assis_req(8,1,5) = -999;
%ph2
num_mode_switches(6,2,5) = -999;
total_time_all(6,2,5) = -999;
alpha_all(6,2,5) = -999;
num_assis_req(6,2,5) = -999;
%H7
num_mode_switches([3,13], 1,6) = -999;
total_time_all([3,13], 1, 6) = -999;
alpha_all([3,13], 1, 6) = -999;
num_assis_req([3,13], 1, 6) = -999;
%H8
num_mode_switches([13, 15], 1,7) = -999;
total_time_all([13,15], 1, 7) = -999;
alpha_all([13,15], 1, 7) = -999;
num_assis_req([13,15], 1, 7) = -999;

%% THIS CHUNK OF CODE IS USED TO PLOT THE PATTERN OF USER INITITAED MODE SWITCHES AND DISAMB REQUESTS. THE BLACKDOTS AND THE RED DOTS. 
%tHIS IS DONE BY RE-RUNNING THIS CHUNK OF CODE MULTIPLE TIMES WITH
%DIFFERENT VALUES OF VARIABLE inter AND task AND CHANGING THE plt1 and plt2
%values which determine which subplot is to be used for plotting. 
plt1 = 2; plt2 = 2;
% figure;
subplot(1,2,plt1);
hold on; grid on;
% axis([0,1,1,20]);
ylim([0,20]);
inter = 'HA'; task = 'PO'; % which interface/task combination.

for i=1:total_subjects
    user = subList{i};
    trialId = trialList(i);
    fnames = dir(user);
    numfids = length(fnames);
    index = 0;
    for j=3:numfids
        n = fnames(j).name;
%         load(n);
        temp = n; n(end-3:end) = []; %remove .mat extension
        if length(n) == 12
            trialnum = str2double(n(end-1:end));
        else
            trialnum = str2double(n(end));
        end
        if strcmp(n(3:5), 'PH1')
            ph = 1;
        elseif strcmp(n(3:5), 'PH2')
            ph = 2;
        end
        subid = str2double(n(2)) - 1;
        total_time = total_time_all(trialnum, ph, subid);
        if strcmp(n(8:9), inter) && strcmp(n(6:7), task) %only plot for the interface/task combination of interest. 
            if num_assis_req(trialnum, ph, subid) > 0
             %scatter plot for assistance requests. 
             %for each subject plot the dots slightly above each other. 
                h1 = scatter(assistance_req_time_stamps{trialnum, ph, subid}/total_time, (i*2 + index*0.1)*ones(length(assistance_req_time_stamps{trialnum, ph, subid}), 1), 40, 'r', 'filled');
%                 h1 = scatter(assistance_req_time_stamps{trialnum, ph, subid}, (i*2 + index*0.1)*ones(length(assistance_req_time_stamps{trialnum, ph, subid}), 1), 40, 'r', 'filled');
                
%               collect all data points for histogram. 
                hist_ar_norm_ts = [hist_ar_norm_ts; ar_norm_ts{trialnum, ph, subid}]; %normalized time stamps for assistance requests.
%                 ms = mode_switch_time_stamps{trialnum, ph, subid};
%                 ar = assistance_req_time_stamps{trialnum, ph, subid};
%                 com = sort([ms;ar]);
%                 first_disamb_req = [first_disamb_req ; find(com == ar(1))]; 
            end
        end
        if strcmp(n(8:9), inter) && strcmp(n(6:7), task) %scatter plot for user initiated mode switches. 
            disp(num_mode_switches(trialnum, ph, subid));
            if num_mode_switches(trialnum, ph, subid) > 0
                h2 = scatter(mode_switch_time_stamps{trialnum, ph, subid}/total_time, (i*2 + index*0.1)*ones(length(mode_switch_time_stamps{trialnum, ph, subid}), 1), 30, 'k', 'filled', 'MarkerFaceAlpha', 0.5);
%                 h2 = scatter(mode_switch_time_stamps{trialnum, ph, subid}, (i*2 + index*0.1)*ones(length(mode_switch_time_stamps{trialnum, ph, subid}), 1), 30, 'k', 'filled', 'MarkerFaceAlpha', 0.5);

            end
            
            %draw the lines for the trails. 
            if num_mode_switches(trialnum, ph, subid) >= 0
                line([0, 1.0], [i*2 + index*0.1, i*2 + index*0.1], 'Color', [0.01,0.01, 0.01, 0.2], 'LineWidth', 0.001);
            else
                line([0, 1.0], [i*2 + index*0.1, i*2 + index*0.1], 'Color', [0.01,0.01, 0.01, 0.2], 'LineWidth', 0.001);
            end
            index = index + 1;
        end
        
    end
end

%%
set(gca, 'fontWeight', 'bold', 'YTickLabel', {1,2,3,4,5,6,7,8, [], []});
ylabel('\bf \fontsize{11} Subject ID');
% xlabel('\bf \fontsize{11} Normalized Time');
xlabel('\bf \fontsize{11} Time (s)');
if strcmp(inter, 'J2')
    inter_title = 'Joystick';
else
    inter_title = 'Headarray';
end
if strcmp(task, 'PO')
    task_title = 'MultiStep';
else
    task_title = 'SingleStep';
end
title(strcat(inter_title));
% legend('Disamb', 'Manual');
legend([h2, h1], 'Manual', 'Disamb');
% subplot(1,2,plt2);
% h = histogram(hist_ar_norm_ts, ceil(sqrt(length(hist_ar_norm_ts))));
% title(strcat(inter_title, '/', task_title));
% xlabel('\bf \fontsize{11} Normalized Time');
% ylabel('\bf \fontsize{11} Num of ondemand');
% xlim([0,1]);
% text(0.4, 12, strcat('Skewness = ',  num2str(round(skewness(hist_ar_norm_ts), 2))));
fprintf('The skewness of assistance requests is %f\n', skewness(hist_ar_norm_ts));

% subplot(2,2,plt1);
% h = histogram(first_disamb_req);
% title(strcat(inter, ',', task));
% xlabel('\bf \fontsize{11}  First Disamb Index');
% ylabel('\bf \fontsize{11} Hist Count');
%% This CHUNK OF CODE IS USED FOR THE PLOTTING GOAL PROBABILITIES. 
% close all;
 
% VARIABLE TO HOLD THE TIME DIFFERENCE FROM DISAMB REQUEST AND THE PEAK IN
% GOAL CONFIDENCE. 
peak_conf_from_disamb = zeros(trials_per_phase, length(phases), total_subjects);
 
for i=1:total_subjects
    user = subList{i};
    trialId = trialList(i);
    fnames = dir(user);
    numfids = length(fnames);
    for j=3:numfids
        n = fnames(j).name;
%         load(n);
        temp = n; n(end-3:end) = []; %remove .mat extension
        if length(n) == 12
            trialnum = str2double(n(end-1:end));
        else
            trialnum = str2double(n(end));
        end
        if strcmp(n(3:5), 'PH1')
            ph = 1;
        elseif strcmp(n(3:5), 'PH2')
            ph = 2;
        end
        disp(n);
        subid = str2double(n(2)) - 1;
        total_time = total_time_all(trialnum, ph, subid);
        gp = goal_probabilities_all{trialnum, ph, subid};
        ng = size(gp, 2) - 1;
        
        
        %PLOT THE GOAL CONFIDENCES EVOLUTION. tHIS IS WHAT IS USED ON
        %FIGURE 9 IN THE PAPER. 
        figure;
        plot(gp(:, end), gp(:,1:end-1), 'LineWidth', 1.5); hold on; grid on;
%         if num_mode_switches(trialnum, ph, subid) > 0
%             scatter(mode_switch_time_stamps{trialnum, ph, subid}/total_time, (1/ng)*ones(length(mode_switch_time_stamps{trialnum, ph, subid}), 1), 30, 'k', 'filled', 'MarkerFaceAlpha', 0.5);
%         end
        if num_assis_req(trialnum, ph, subid) > 0
            
            if num_mode_switches(trialnum, ph, subid) > 0
                h1 = scatter(mode_switch_time_stamps{trialnum, ph, subid}, (1/ng)*ones(length(mode_switch_time_stamps{trialnum, ph, subid}), 1), 30, 'k', 'filled');
            end
            h2 = scatter(assistance_req_time_stamps{trialnum, ph, subid}, (1/ng)*ones(length(assistance_req_time_stamps{trialnum, ph, subid}), 1), 40, 'r', 'filled');
        
        
            ar_ts = assistance_req_time_stamps{trialnum, ph, subid};
            gp_ts = gp(:, end);
            t_from_ar = nan(length(ar_ts), 1); % TIME OF GOAL PROBABILITY PEAK FROM THE ASSISTANCE REQUEST. 
            if length(ar_ts) > 1
                for kk=1:length(ar_ts)-1
                    ar_ts_prev = ar_ts(kk);
                    ar_ts_next = ar_ts(kk+1);
                    %find time indices in gp that is between prev and next.
                    t_ind = intersect(find(gp_ts > ar_ts_prev), find(gp_ts <= ar_ts_next));
                    gp_snip = gp(t_ind, :);
                    gp_max = max(gp_snip(:, 1:end-1), [], 2);
                    [~, locs] = findpeaks(gp_max, 'MinPeakHeight', 1/ng + 0.08);
                    if ~isempty(locs)
                        t_from_ar(kk) = gp_snip(locs(1), end) - ar_ts_prev;
                    end
                    %Then find maximum of value of gp. compute distance with
                    %previous
                end
                ar_ts_prev = ar_ts(end);
                t_ind = find(gp_ts > ar_ts_prev);
                gp_snip = gp(t_ind, :);
                gp_max = max(gp_snip(:, 1:end-1), [], 2);
                [~, locs] = findpeaks(gp_max, 'MinPeakHeight', 1/ng + 0.08);
                if ~isempty(locs)
                    t_from_ar(end) = gp_snip(locs(1), end) - ar_ts_prev;
                end
                %deal with last assistance req outside the loop
            else
                %deal with the case when you have only one assis rew
                ar_ts_prev = ar_ts(1);
                t_ind = find(gp_ts > ar_ts_prev);
                gp_snip = gp(t_ind, :);
                gp_max = max(gp_snip(:, 1:end-1), [], 2);
                [pks, locs] = findpeaks(gp_max, 'MinPeakHeight', 1/ng + 0.08);
                if ~isempty(locs)
                    t_from_ar = gp_snip(locs(1), end) - ar_ts_prev;
                end
            end
            if ~isnan(nanmean(t_from_ar))
                peak_conf_from_disamb(trialnum, ph, subid) = nanmean(t_from_ar);
            else
                peak_conf_from_disamb(trialnum, ph, subid) = -999;
            end
            disp(t_from_ar);
            %USE A BREAK POINT IN THE NEXT LINE TO VISUALIZE THE GOAL
            %PROBABILITY EVOLUTION FOR EACH TRIAL. 
            close all;
        end
    end
end

%%
function [td] = trim_data(d, isrow)
    if isrow
        ts = d(end, :);
    else
        ts = d(:, end);
    end
    first_t = find(ts < 0);
    first_t = first_t(end);
    if isrow()
        d(:, 1:first_t) = [];
    else
        d(1:first_t, :) = [];
    end
    td = d;
end




