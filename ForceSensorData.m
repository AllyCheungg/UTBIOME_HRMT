%% Acquire and analyze data from a force sensor

%% Connect to Arduino

a = arduino;

%% Take a single measurement
% Analog outputs a number between 0 and 1024
% representing 0v to 5V
value = readVoltage(a,'A0');  

% Assume linear relationship between voltage
% and weight

% mass ranges from 0 kg to 30 kg

mass = 30 * value / 5;
weight = mass * 9.8;

fprintf('\nVoltage Reading: %0.001f    Weight Reading: %0.001f\n', value, weight)

%% Record and plot 10 seconds of resistance data

index = 0;
R = zeros(1e4,1);
t = zeros(1e4,1);

tic
while toc < 10
    index = index + 1;
    % Read current voltage value
    v = readVoltage(a,'A0');
    mass = 30 * v / 5;
    weight = mass * 9.8;
    R(index) = weight;
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
ylabel('Force (N)')
title('Ten Seconds of Force Sensor Data')
set(gca,'xlim',[t(1) t(index)])