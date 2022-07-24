%% Acquire and analyze data from a stretch sensor

%% Connect to Arduino
% Use the arduino command to connect to an Arduino device.

a = arduino;

%% Take a single measurement
% // relaxed state: R = 350 ohms per inch
% // pulling = resistance increase
% // current relax state length: 6 inches = 2.1k ohms
% // stretched length: X inches
% // Once the force is released, the rubber will shrink back
% // Its not very 'fast' and it takes a minute or two to revert to its original length.
% // Analog outputs a number between 0 and 1024 representing 0V to 5V.

value = readVoltage(a,'A0');       % voltage read out
buf = (5.0 / value) - 1;
resistance = 10 / buf;

fprintf('\nVoltage Reading: %0.001f    Resistance Reading: %0.001f\n', value, resistance)

% data makes sense, the resistance is 2.0k ohms

%% Record and plot 10 seconds of resistance data

index = 0;
R = zeros(1e4,1);
t = zeros(1e4,1);

tic
while toc < 10
    index = index + 1;
    % Read current voltage value
    v = readVoltage(a,'A0');
    resist = 10 / ((5.0 / v) - 1);
    R(index) = resist;
    % Get time since starting
    t(index) = toc;
end

% Post-process and plot the data. First remove any excess zeros on the
% logging variables.
R = R(1:index);
t = t(1:index);
% Plot temperature versus time
figure
plot(t,R,'-o')
xlabel('Elapsed time (sec)')
ylabel('Resistance (k\Omega)')
title('Ten Seconds of Stretch Sensor Data')
set(gca,'xlim',[t(1) t(index)])

%% Compute acquisition rate

timeBetweenDataPoints = diff(t);
averageTimePerDataPoint = mean(timeBetweenDataPoints);
dataRateHz = 1/averageTimePerDataPoint;
fprintf('Acquired one data point per %.3f seconds (%.f Hz)\n',...
    averageTimePerDataPoint,dataRateHz)

%% Why is my data so choppy?

measurableIncrementV = 5/1023;
measurableIncrementR = measurableIncrementV*100;

fprintf('The smallest measurable increment of this sensor by the Arduino is \n %f V \n %f k\Omega',...
    measurableIncrementV,measurableIncrementR);

%% Acquire and display live data

figure
h = animatedline;
ax = gca;
ax.YGrid = 'on';
ax.YLim = [65 85];

stop = false;
startTime = datetime('now');
while ~stop
    % Read current voltage value
    v = readVoltage(a,'A0');
    % Calculate temperature from voltage (based on data sheet)
    TempC = (v - 0.5)*100;
    R = 9/5*TempC + 32;    
    % Get current time
    t =  datetime('now') - startTime;
    % Add points to animation
    addpoints(h,datenum(t),R)
    % Update axes
    ax.XLim = datenum([t-seconds(15) t]);
    datetick('x','keeplimits')
    drawnow
    % Check stop condition
    stop = readDigitalPin(a,'D12');
end

%% Plot the recorded data

[timeLogs,tempLogs] = getpoints(h);
timeSecs = (timeLogs-timeLogs(1))*24*3600;
figure
plot(timeSecs,tempLogs)
xlabel('Elapsed time (sec)')
ylabel('Temperature (\circF)')

%% Smooth out readings with moving average filter

smoothedTemp = smooth(tempLogs,25);
tempMax = smoothedTemp + 2*9/5;
tempMin = smoothedTemp - 2*9/5;

figure
plot(timeSecs,tempLogs, timeSecs,tempMax,'r--',timeSecs,tempMin,'r--')
xlabel('Elapsed time (sec)')
ylabel('Temperature (\circF)')
hold on 

%%
% Plot the original and the smoothed temperature signal, and illustrate the
% uncertainty.

plot(timeSecs,smoothedTemp,'r')

%% Save results to a file

T = table(timeSecs',tempLogs','VariableNames',{'Time_sec','Temp_F'});
filename = 'Temperature_Data.xlsx';
% Write table to file 
writetable(T,filename)
% Print confirmation to command line
fprintf('Results table with %g temperature measurements saved to file %s\n',...
    length(timeSecs),filename)
