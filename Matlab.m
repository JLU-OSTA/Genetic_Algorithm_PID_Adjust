delete(instrfindall);
delete(instrfindall);
s=serial('com12');
set(s,'BaudRate',19200,'StopBits',1,'Parity','none','DataBits',8,'InputBufferSize',255);
fopen(s);
x=1:50;
S=[];
sr=[];
read=0;
while sum(size(S))-5<=x(end)
	rd=fread(s,1);
	if rd=='E'
		if sr
			sr=str2num(sr);
			i=i-1;
		end
		S=[sr;S];
		fprintf('We are preparing sample...');
		fprintf(num2str((sum(size(S))-5)/50*100-2));
		fprintf('%%\n');
		sr=[];
		read=0;
	end
	if read==1
		sr=[sr,char(rd)];
	end
	if rd=='S'
		read=1;
	end
end
in=0;
ins=1;
test=1;
kp=0;
ki=0;
kd=0;
lst_gen=zeros(8,3);
err=100*ones(1,3);
lst_err=1000;
tmp_aim=[kp ki kd];
dad=zeros(1,3);
mom=zeros(1,3);
change_rate=0.7;
err_draw=ones(1,3);
fprintf 'Start\n';
var_draw=ones(1,50);
fprintf(['This is the ',num2str(ins),' generation.\n']);
update_k=1;
kpr=[0.19 0.27 0.43 0.51];
kir=[3.41 3.66 4.16 4.42];
kdr=[2.67 2.68 2.70 2.70];
gen=[
kpr(3) kir(3) kdr(3)
kpr(3) kir(3) kdr(2)
kpr(3) kir(2) kdr(2)
kpr(3) kir(2) kdr(3)
kpr(2) kir(2) kdr(3)
kpr(2) kir(2) kdr(2)
kpr(2) kir(3) kdr(2)
kpr(2) kir(3) kdr(3)];
while 1
	rd=fread(s,1);
	if rd=='E'
		if s.BytesAvailable
			fread(s,s.BytesAvailable);
		end
		if sr
			sr=str2num(sr);
		end
		S=[sr;S];
		if sum(size(S))-5 < x(end)
			for i=1:x(end)-sum(size(S))+5
				S=[S(1,:);S];
			end
		end
		if sum(size(S))-5 > x(end)
			for i=1:sum(size(S))-5-x(end)
				S(end,:)=[];
			end
		end
		subplot(2,2,1);
		plot(S(:,1),'-');
		xlim([0,50]);
		kpn=num2str(S(1,3));
		kin=num2str(S(1,4));
		kdn=num2str(S(1,5));
		title(['PWM=',num2str(S(1,2)),'  Kp=',kpn,'  Ki=',kin,'  Kd=',kdn]);
		S1=S(:,1);
		f=abs(fft(S(:,1)));
		f=f(2:end);
		subplot(2,2,2);
		plot(f(1:30,:));
		xlim([1,30]);
		title('Now Sample FFT');
		var_draw=[sum((S([1:30],1)-65).^2),var_draw];
		var_draw(end)=[];
		subplot(2,2,3);
		plot(var_draw,'-');
		title('Now Variance');
		xlim([1,50]);
		subplot(2,2,4);
		plot(err_draw,'-');
		title('Min Variance');
		xlim([1,3]);
		drawnow;
		sr=[];
		read=0;
		tmp_aim=gen(test,:);
		if round(tmp_aim(1),2)==round(S(1,3),2) && round(tmp_aim(2),2)==round(S(1,4),2) && round(tmp_aim(3),2)==round(S(1,5),2)
			in=in+1;
			if in==200
				fwrite(s,'R');
				pause(1.7);
				in=0;
				err(test)=sum(var_draw);
				test=test+1;
				if test==9
					err_draw(end)=[];
					err_draw=[min(lst_err),err_draw];
					ins=ins+1;
					fprintf(['Now we have this range:\n']);
					fprintf(['\t\tKpRange:\t',num2str(kpr),'\n\t\tKiRange:\t',num2str(kir),'\n\t\tKdRange:\t',num2str(kdr),'\n']);
					fprintf(['This is the ',num2str(ins),' generation.\n']);
					%if min(err)<=lst_err
						lst_err=min(err);
					%else
					%	gen=lst_gen;
					%end
					lst_gen=gen;
					gen(1,:)=lst_gen(8,:);
					gen(2,:)=lst_gen(7,:);
					gen(3,:)=lst_gen(5,:);
					gen(4,:)=lst_gen(6,:);
					gen(5,:)=lst_gen(2,:);
					gen(6,:)=lst_gen(1,:);
					gen(7,:)=lst_gen(3,:);
					gen(8,:)=lst_gen(4,:);
					dl=find(err==min(err));
					dad=gen(dl,:);
					ml=find(err==min(err(find(err>min(err)))));
					mom=gen(ml,:);
					if abs(dad(1)-mom(1))<=0.02
						if dad(1) > (kpr(1)+kpr(4))/2
							kpr(1)=kpr(2);
							kpr(2)=kpr(1)+(kpr(4)-kpr(1))/4;
							kpr(3)=kpr(1)+3*(kpr(4)-kpr(1))/4;
						else
							kpr(4)=kpr(3);
							kpr(2)=kpr(1)+(kpr(4)-kpr(1))/4;
							kpr(3)=kpr(1)+3*(kpr(4)-kpr(1))/4;
						end
						dad(1)=kpr(2);
						mom(1)=kpr(3);
					end
					if abs(dad(2)-mom(2))<=0.02
						if dad(2) > (kir(1)+kir(4))/2
							kir(1)=kir(2);
							kir(2)=kir(1)+(kir(4)-kir(1))/4;
							kir(3)=kir(1)+3*(kir(4)-kir(1))/4;
						else
							kir(4)=kir(3);
							kir(2)=kir(1)+(kir(4)-kir(1))/4;
							kir(3)=kir(1)+3*(kir(4)-kir(1))/4;
						end
						dad(2)=kir(2);
						mom(2)=kir(3);
					end
					if abs(dad(3)-mom(3))<=0.02
						if dad(3) > (kdr(1)+kdr(4))/2
							kdr(1)=kdr(2);
							kdr(2)=kdr(1)+(kdr(4)-kdr(1))/4;
							kdr(3)=kdr(1)+3*(kdr(4)-kdr(1))/4;
						else
							kdr(4)=kdr(3);
							kdr(2)=kdr(1)+(kdr(4)-kdr(1))/4;
							kdr(3)=kdr(1)+3*(kdr(4)-kdr(1))/4;
						end
						dad(3)=kdr(2);
						mom(3)=kdr(3);
					end
					kpr(2)=min([dad(1),mom(1)]);
					kpr(3)=max([dad(1),mom(1)]);
					kir(2)=min([dad(2),mom(2)]);
					kir(3)=max([dad(2),mom(2)]);
					kdr(2)=min([dad(3),mom(3)]);
					kdr(3)=max([dad(3),mom(3)]);
					kpr(1)=kpr(2)-(kpr(3)-kpr(2))/2;
					kpr(4)=kpr(3)+(kpr(3)-kpr(2))/2;
					kir(1)=kir(2)-(kir(3)-kir(2))/2;
					kir(4)=kir(3)+(kir(3)-kir(2))/2;
					kdr(1)=kdr(2)-(kdr(3)-kdr(2))/2;
					kdr(4)=kdr(3)+(kdr(3)-kdr(2))/2;
					for col1=1:8
						if col1<=4
							gen(col1,1)=dad(1);
						else
							gen(col1,1)=mom(1);
						end
						col2=mod(col1,4);
						if col2==0
							col2=4;
						end
						if col2<=2
							gen(col1,2)=dad(2);
						else
							gen(col1,2)=mom(2);
						end
						if mod(col1,2)==1
							gen(col1,3)=dad(3);
						else
							gen(col1,3)=mom(3);
						end
						%for ch=1:3
						%	if rand(1,1)<change_rate
						%		if rand(1,1)<0.5
						%			if gen(col1,ch)>0
						%				gen(col1,ch)=gen(col1,ch)-0.01;
						%			end
						%		else
						%			if gen(col1,ch)<5
						%				gen(col1,ch)=gen(col1,ch)+0.01;
						%			end
						%		end
						%	end
						%end
					end
					test=1;
				end
				fprintf(['\tNow we are testing child ',num2str(test),'.\n']);
				fprintf(['\t\tKp=',num2str(gen(test,1)),'\tKi=',num2str(gen(test,2)),'\tKd=',num2str(gen(test,3)),'\n']);
			end
		end
		update_k=update_k+1;
		if update_k==50
			kp=S(1,3);
			ki=S(1,4);
			kd=S(1,5);
			update_k=0;
		end
		while round(kp,2)~=round(tmp_aim(1),2) || round(ki,2)~=round(tmp_aim(2),2) || round(kd,2)~=round(tmp_aim(3),2)
			if round(kp,2)<round(tmp_aim(1),2)
				kp=kp+0.01;
				fwrite(s,'P');
				in=0;
			end
			if round(kp,2)>round(tmp_aim(1),2)
				kp=kp-0.01;
				fwrite(s,'p');
				in=0;
			end
			if round(ki,2)<round(tmp_aim(2),2)
				ki=ki+0.01;
				fwrite(s,'I');
				in=0;
			end
			if round(ki,2)>round(tmp_aim(2),2)
				ki=ki-0.01;
				fwrite(s,'i');
				in=0;
			end
			if round(kd,2)<round(tmp_aim(3),2)
				kd=kd+0.01;
				fwrite(s,'D');
				in=0;
			end
			if round(kd,2)>round(tmp_aim(3),2)
				kd=kd-0.01;
				fwrite(s,'d');
				in=0;
			end
			pause(20/1000);
		end
	end
	if read==1
		sr=[sr,char(rd)];
	end
	if rd=='S'
		read=1;
	end
end
fclose(s)