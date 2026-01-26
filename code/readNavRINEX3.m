function Nav_D =  readNavRINEX3(filepath)

Nav_D = struct();

SIZE = initiate(filepath);

if SIZE.GPS
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(36, SIZE.GPS);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'G')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%5
            arrdata(23:26, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%6
            arrdata(27:30, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%7
            arrdata(31:34, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%8
            if numel(temp{:}) < 2
                temp{:} = [temp{:}; nan]; % 解决GPS缺失数据导致数据重复问题
            end
            arrdata(35:36, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %GPS
    VarNames = {'SatelliteID', 'SVClockBias', 'SVClockDrift', 'SVClockDriftRate', ...
        'IODE', 'Crs', 'Delta_n', 'M0', ...
        'Cuc', 'Eccentricity', 'Cus', 'sqrtA', ...
        'Toe', 'Cic', 'OMEGA0', 'Cis', ...
        'i0', 'Crc', 'omega', 'OMEGA_DOT', ...
        'IDOT', 'L2ChannelCodes', 'GPS_Week', 'L2PDataFlag', ...
        'SVAccuracy', 'SVHealth', 'TGD', 'IODC', ...
        'TransmissionTime', 'FitInterval'};

    Nav_D.GPS = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);
end

if SIZE.GLONASS
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(22, SIZE.GLONASS);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'R')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %GLONASS
    VarNames = {'PRN', 'SVbias', 'SVdrift', 'Message_frame_time', ...
        'Satellite_X', 'velocity_Xdot', 'X_acceleration', 'health', ...
        'Satellite_Y', 'velocity_Ydot', 'Y_acceleration', 'frequency_number', ...
        'Satellite_Z', 'velocity_Zdot', 'Z_acceleration', 'Age_of_oper'};

    Nav_D.GLONASS = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);

end

if SIZE.Galileo
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(34, SIZE.Galileo);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'E')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%5
            arrdata(23:26, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%6
            arrdata(27:29, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%7
            arrdata(30:33, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%8
            arrdata(34, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %Galileo
    VarNames = {'PRN', 'SVbias', 'SVdrift', 'SVdrift_rate', ...
        'IODE', 'Crs', 'Delta_n', 'M0', ...
        'Cuc', 'Eccentricity', 'Cus', 'sqrtA', ...
        'Toe', 'Cic', 'OMEGA0', 'Cis', ...
        'i0', 'Crc', 'omega', 'OMEGA_DOT', ...
        'IDOT', 'Data_sources', 'GPS_Week', ...
        'SISA', 'SV_health', 'BGD_E5a/E1', 'BGD_E5b/E1', ...
        'Transmission'};

    Nav_D.Galileo = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);

end

if SIZE.QZSS
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(36, SIZE.QZSS);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'J')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%5
            arrdata(23:26, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%6
            arrdata(27:30, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%7
            arrdata(31:34, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%8
            arrdata(35:36, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %QZSS
    VarNames = {'PRN', 'SVbias', 'SVdrift', 'SVdrift_rate', ...
        'IODE', 'Crs', 'Delta_n', 'M0', ...
        'Cuc', 'Eccentricity', 'Cus', 'sqrtA', ...
        'Toe', 'Cic', 'OMEGA0', 'CIS', ...
        'i0', 'Crc', 'omega', 'OMEGA_DOT', ...
        'IDOT', 'L2_channel', 'GPS_Week', 'L2P_flag', ...
        'SV_accuracy', 'SV_health', 'TGD', 'IODC', ...
        'Transmission', 'Fit_Interval'};

    Nav_D.QZSS = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);

end

if SIZE.BDS
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(36, SIZE.BDS);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'C')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%5
            arrdata(23:26, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%6
            arrdata(27:30, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%7
            arrdata(31:34, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%8
            arrdata(35:36, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %BDS
    VarNames = {'PRN', 'SVbias', 'SVdrift', 'SVdrift_rate', ...
        'AODE', 'Crs', 'Delta_n', 'M0', ...
        'Cuc', 'Eccentricity', 'Cus', 'sqrtA', ...
        'Toe', 'Cic', 'OMEGA0', 'Cis', ...
        'i0', 'Crc', 'omega', 'OMEGA_DOT', ...
        'IDOT', 'SPARE1', 'BDT_Week', 'SPARE2', ...
        'SV_accuracy', 'SatH1', 'TGD1_B1/B3', 'TGD2_B2/B3', ...
        'Transmission', 'AODC_ICD'};

    Nav_D.BDS = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);

end

if SIZE.NavIC
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(32, SIZE.NavIC);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'I')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%5
            arrdata(23:26, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%6
            arrdata(27:28, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%7
            arrdata(29:31, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%8
            arrdata(32, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %NavIC
    VarNames = {'PRN', 'SVbias', 'SVdrift', 'SVdrift_rate', ...
        'IODEC', 'Crs', 'Delta_n', 'M0', ...
        'Cuc', 'Eccentricity', 'Cus', 'sqrtA', ...
        'Toe', 'Cic', 'OMEGA0', 'Cis', ...
        'i0', 'Crc', 'omega', 'OMEGA_DOT', ...
        'IDOT', 'IRN_Week', ...
        'User_Range_Accuracy', 'Health_frame', 'TGD', ...
        'Transmission'};

    Nav_D.NavIC = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);

end

if SIZE.SBAS
    i = 1;
    fid = fopen(filepath);
    arrdata = zeros(22, SIZE.SBAS);
    fid = skip(fid);
    while ~feof(fid)
        line = fgetl(fid);
        if strcmp(line(1), 'S')
            temp = textscan(line(2:80), "%f");%1
            arrdata(1:10, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%2
            arrdata(11:14, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%3
            arrdata(15:18, i) = temp{:};

            line = fgetl(fid);
            temp = textscan(line(2:80), "%f");%4
            arrdata(19:22, i) = temp{:};

            i = i + 1;
        end
    end

    fclose(fid);

    arrdata = arrdata';
    epochIdx = [2, 3, 4, 5, 6, 7];
    t = datetime(arrdata(:, epochIdx));
    arrdata(:, epochIdx) = [];
    %SBAS
    VarNames = {'PRN', 'SVbias', 'SVdrift', 'Transmission', ...
        'Satellite_X', 'velocity_Xdot', 'X_acceleration', 'health', ...
        'Satellite_Y', 'velocity_Ydot', 'Y_acceleration', 'Accuracy_code', ...
        'Satellite_Z', 'velocity_Zdot', 'Z_acceleration', 'IODN'};

    Nav_D.SBAS = array2timetable(arrdata, 'RowTimes', t, "VariableNames", VarNames);

end
end

function SIZE =  initiate(path)

G = 0;
R = 0;
E = 0;
J = 0;
C = 0;
I = 0;
S = 0;

fid1 = fopen(path);

fid1 = skip(fid1);

while ~feof(fid1)
    line = fgetl(fid1);
    switch line(1)
        case 'G' % GPS
            G = G + 1;
        case 'R' % GLONASS
            R = R + 1;
        case 'E' % Galileo
            E = E + 1;
        case 'J' % QZSS
            J = J + 1;
        case 'C' % BDS
            C = C + 1;
        case 'I' % NavIC
            I = I + 1;
        case 'S' % SBAS
            S = S + 1;
    end
end

fclose(fid1);

SIZE = struct('GPS', G, 'GLONASS', R, 'Galileo', E, 'QZSS', J, 'BDS', ...
    C, 'NavIC', I, 'SBAS', S);
end

function fid = skip(fid1)
while ~feof(fid1)
    line = fgetl(fid1);
    if contains(line, 'END OF HEADER')
        break
    end
end
fid = fid1;
end
