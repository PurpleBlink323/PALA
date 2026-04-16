function WF_RenderAggregatePhysiologyPlots(aggregateTable, summaryThresholdUm)
cpp = aggregateTable.CPP;

figure;
subplot(3, 2, 1);
plot(cpp, aggregateTable.CMC_Normalized, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized CMC');
title(sprintf('Micro vessel, D < %d um', round(summaryThresholdUm)));
grid on;

subplot(3, 2, 2);
plot(cpp, aggregateTable.CMAC_Normalized, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized CMAC');
title(sprintf('Macro vessel, D >= %d um', round(summaryThresholdUm)));
grid on;

subplot(3, 2, 3);
plot(cpp, aggregateTable.DensityMicro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Micro density');
title(sprintf('Micro density, D < %d um', round(summaryThresholdUm)));
grid on;

subplot(3, 2, 4);
plot(cpp, aggregateTable.DensityMacro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Macro density');
title(sprintf('Macro density, D >= %d um', round(summaryThresholdUm)));
grid on;

subplot(3, 2, 5);
plot(cpp, aggregateTable.MeanVelMicro_Normalized, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized mean velocity');
title(sprintf('Mean micro velocity, D < %d um', round(summaryThresholdUm)));
grid on;

subplot(3, 2, 6);
plot(cpp, aggregateTable.MeanVelMacro_Normalized, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized mean velocity');
title(sprintf('Mean macro velocity, D >= %d um', round(summaryThresholdUm)));
grid on;

figure;
subplot(1, 2, 1);
plot(cpp, aggregateTable.MeanDiaMicro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Mean micro diameter (\mum)');
title(sprintf('Micro diameter, D < %d um', round(summaryThresholdUm)));
grid on;

subplot(1, 2, 2);
plot(cpp, aggregateTable.MeanDiaMacro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Mean macro diameter (\mum)');
title(sprintf('Macro diameter, D >= %d um', round(summaryThresholdUm)));
grid on;
