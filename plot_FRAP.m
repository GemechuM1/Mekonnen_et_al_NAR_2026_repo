% fit norm_FRAP with f(t) = A(1 - e^(-t/tau))
figure, scatter(t, b_int, 'k.')
fit_func = 'A*(1-exp(-t/tau))';
fit_type = fittype(fit_func, 'dependent',{'b_int'},'independent',{'t'}, 'coefficients',{'A', 'tau'});
[fitted_curve_int, gof_int] = fit(t, b_int, fit_type);
hold on, plot(fitted_curve_int)
xlabel('Time (s)'), ylabel('Normalized Intensity')
legend('data', 'fitted curve', 'Location', 'southeast')

% mobile fraction
f_mobile = fitted_curve_int.A;
intervals = confint(fitted_curve_int);
A_range = intervals(:,1);
delta_A = abs(f_mobile - A_range(1));

% display tau with 95% confidence interval
tau = fitted_curve_int.tau;
tau_range = intervals(:,2);
delta_tau = abs(tau - tau_range(1));
r_square = gof_int.rsquare;

% display on plot
annotation('textbox',[.55 .45 .31 .2],'String',sprintf('tau = %.3f +/- %.4f s', tau, delta_tau),'EdgeColor','k')
annotation('textbox',[.56 .47 .31 .15],'String',sprintf('r^2 = %.5f', r_square),'EdgeColor','none')
annotation('textbox',[.55 .33 .31 .13],'String',sprintf('f mobile= %.3f +/- %.4f', f_mobile, delta_A),'EdgeColor','none')

% save plot
%saveas(gcf, 'fit_plot.png'])