classdef mazeCls < handle
    %mazeCls a class to host maze utilities by Rodney Meyer
    %   this class is modified from the original maze code by Rodney Meyer,
    %   it exposes internal functions of the file maze.m and is therefore
    %   for advanced use such as developing a maze solver.
    %
    %   New functions implemented include a state transition function
    %   transition() and a transition visualization function
    %   show_transition().
    
    properties
        ptr_up % array for storing result of the next state if going up
        ptr_down
        ptr_left
        ptr_right
        row % number of rows in maze
        col % number of columns in maze
        pattern % maze pattern
        rr % not clear
        cc % not clear
        state % not clear
        % available actions: up 1, right 2, down 3, left 4
        action_space = [1,2,3,4]; % required by dfsCls class
        
    end
    
    methods
        function obj = mazeCls(row,col,pattern)
            %mazeCls Construct a maze
            % mazeCls(obj,row,col,pattern) Constructs a maze object with
            % row and column numbers and pattern specification. Patterns
            % can be random(r), vertical(v), horizontal(h), 
            % checkerboard(c), spiral(s), and burst(b)
            obj.row = row;
            obj.col = col;
            obj.pattern = pattern;
            
            rand('state',sum(100*clock))
            
            [cc,rr]=meshgrid(1:col,1:row);
            state = reshape([1:row*col],row,col); % state identifies connected regions
            id = reshape([1:row*col],row,col); % id identifies intersections of maze
            
            % create pointers to adjacent intersections
            ptr_left = zeros(size(id));
            ptr_up = zeros(size(id));
            ptr_right = zeros(size(id));
            ptr_down = zeros(size(id));
            
            ptr_left(:,2:size(id,2)) = id(:,1:size(id,2)-1);
            ptr_up(2:size(id,1),:) = id(1:size(id,1)-1,:);
            ptr_right(:,1:size(id,2)-1) = id(:,2:size(id,2));
            ptr_down(1:size(id,1)-1,:) = id(2:size(id,1),:);
            
            % sort graph entities by id
            the_maze = cat(2,reshape(id,row*col,1),reshape(rr,row*col,1),reshape(cc,row*col,1),reshape(state,row*col,1),...
                reshape(ptr_left,row*col,1),reshape(ptr_up,row*col,1),reshape(ptr_right,row*col,1),reshape(ptr_down,row*col,1)  );

            the_maze = sortrows(the_maze);

            id=the_maze(:,1);
            rr=the_maze(:,2);
            cc=the_maze(:,3);
            state=the_maze(:,4);
            ptr_left=the_maze(:,5);
            ptr_up=the_maze(:,6);
            ptr_right=the_maze(:,7);
            ptr_down=the_maze(:,8);
            
            clear the_maze;
            
            % create a random maze
            [state, ptr_left, ptr_up, ptr_right, ptr_down]=...
                obj.make_pattern(row,col,pattern,id, rr, cc, state, ptr_left, ptr_up, ptr_right, ptr_down);
            
            obj.ptr_left = ptr_left;
            obj.ptr_up = ptr_up;
            obj.ptr_right = ptr_right;
            obj.ptr_down = ptr_down;
            obj.rr = rr;
            obj.cc = cc;
            obj.state = state;
        end
        
        function [state, ptr_left, ptr_up, ptr_right, ptr_down]=...
                make_pattern(obj,row,col,pattern,id, rr, cc, state, ptr_left, ptr_up, ptr_right, ptr_down)
            %make_pattern Make a maze pattern
            while max(state)>1 % remove walls until there is one simply connected region
                tid=ceil(col*row*rand(15,1)); % get a set of temporary ID's
                cityblock=cc(tid)+rr(tid); % get distance from the start
                is_linked=(state(tid)==1); % The start state is in region 1 - see if they are linked to the start
                temp = sortrows(cat(2,tid,cityblock,is_linked),[3,2]); % sort id's by start-link and distance
                tid = temp(1,1); % get the id of the closest unlinked intersection

                % The pattern is created by selective random removal of vertical or 
                % horizontal walls as a function of position in the maze. I find the
                % checkerboard option the most challenging. Other patterns can be added
                switch upper(pattern) 
                case 'C' % checkerboard
                    dir = ceil(8*rand);
                    nb=3;
                    block_size =  min([row,col])/nb;
                    while block_size>12
                        nb=nb+2;
                        block_size =  min([row,col])/nb;
                    end
                    odd_even = (ceil(rr(tid)/block_size)*ceil(col/block_size) + ceil(cc(tid)/block_size));
                    if odd_even/2 == floor(odd_even/2)
                        if dir>6
                            dir=4;
                        end
                        if dir>4
                            dir=3;
                        end
                    else
                        if dir>6
                            dir=2;
                        end
                        if dir>4
                            dir=1;
                        end
                    end
                case 'B' % burst
                    dir = ceil(8*rand);
                    if abs((rr(tid)-row/2))<abs((cc(tid)-col/2))
                        if dir>6
                            dir=4;
                        end
                        if dir>4
                            dir=3;
                        end
                    else
                        if dir>6
                            dir=2;
                        end
                        if dir>4
                            dir=1;
                        end
                    end
                case 'S' %spiral
                    dir = ceil(8*rand);
                    if abs((rr(tid)-row/2))>abs((cc(tid)-col/2))
                        if dir>6
                            dir=4;
                        end
                        if dir>4
                            dir=3;
                        end
                    else
                        if dir>6
                            dir=2;
                        end
                        if dir>4
                            dir=1;
                        end
                    end
                case 'V'
                    dir = ceil(8*rand);
                    if dir>6
                        dir=4;
                    end
                    if dir>4
                        dir=3;
                    end
                case 'H'
                    dir = ceil(8*rand);
                    if dir>6
                        dir=2;
                    end
                    if dir>4
                        dir=1;
                    end
                    otherwise % random
                    dir = ceil(4*rand);
                end

                % after a candidate for wall removal is found, the candidate must pass
                % two conditions. 1) it is not an external wall  2) the regions on
                % each side of the wall were previously unconnected. If successful the
                % wall is removed, the connected states are updated to the lowest of
                % the two states, the pointers between the connected intersections are
                % now negative.
                switch dir
                case -1

                case 1
                    if ptr_left(tid)>0 & state(tid)~=state(ptr_left(tid))
                        state( state==state(tid) | state==state(ptr_left(tid)) )=min([state(tid),state(ptr_left(tid))]);
                        ptr_right(ptr_left(tid))=-ptr_right(ptr_left(tid));
                        ptr_left(tid)=-ptr_left(tid);
                    end
                case 2
                    if ptr_right(tid)>0 & state(tid)~=state(ptr_right(tid))
                        state( state==state(tid) | state==state(ptr_right(tid)) )=min([state(tid),state(ptr_right(tid))]);
                        ptr_left(ptr_right(tid))=-ptr_left(ptr_right(tid));
                        ptr_right(tid)=-ptr_right(tid);
                    end
                case 3
                    if ptr_up(tid)>0 & state(tid)~=state(ptr_up(tid))
                        state( state==state(tid) | state==state(ptr_up(tid)) )=min([state(tid),state(ptr_up(tid))]);
                        ptr_down(ptr_up(tid))=-ptr_down(ptr_up(tid));
                        ptr_up(tid)=-ptr_up(tid);
                    end
                case 4
                    if ptr_down(tid)>0 & state(tid)~=state(ptr_down(tid))
                        state( state==state(tid) | state==state(ptr_down(tid)) )=min([state(tid),state(ptr_down(tid))]);
                        ptr_up(ptr_down(tid))=-ptr_up(ptr_down(tid));
                        ptr_down(tid)=-ptr_down(tid);
                    end
                otherwise
                    dir
                    error('quit')
                end

            end
        end
        
        function next_state = transition(obj,cur_state,action)
            %transition The maze state transition function
            % transition(obj,cur_state,action) moves the position in maze
            % to a next state provided the current state cur_state and the
            % action.
            % Inputs:
            % cur_state: 1x2 int, current state grid location
            % action: int, up 1, right 2, down 3, left 4
            %
            % The maze state indices are column major, i.e., the order
            % first fills the first column, then the second column, etc.
            %
            % The sign of ptr_* indicate whether there is a wall or passage
            % in the direction indicated; the absolute value of ptr_*
            % indicate the next state index if it is a passage. If it is a
            % wall, the state stays where it was after action.
            %
            % Action convention: up 1, right 2, down 3, left 4
            
            % convert the 1x2 state indexing to the 1D column major index
            cur_row = cur_state(1);
            cur_col = cur_state(2);
            cur_s = (cur_col-1)*obj.row + cur_row;
            % assume that the state cannot move unless proven otherwise
            next_s = cur_s;
            % decide possibility of crossing by checking the respective
            % ptr_* value
            if action == 1 && cur_row > 1 && obj.ptr_up(cur_s) < 0
                % condition: not in the top row, and passage above exits
                next_s = abs(obj.ptr_up(cur_s));
            elseif action == 2 && cur_col < obj.col && obj.ptr_right(cur_s) < 0
                % condition: not in the right-most column, and passage right
                % exists
                next_s = abs(obj.ptr_right(cur_s));
            elseif action == 3 && cur_row < obj.row && obj.ptr_down(cur_s) < 0
                % condition: not in the bottom row, and passage down exists
                next_s = abs(obj.ptr_down(cur_s));
            elseif action == 4 && cur_col > 1 && obj.ptr_left(cur_s) < 0
                % condition: not in the left-most row, and passage left
                % exists
                next_s = abs(obj.ptr_left(cur_s));
            end
            % convert back to 1x2 state indexing
            if mod(next_s,obj.row) ~= 0
                next_row = mod(next_s,obj.row);
            else
                next_row = obj.row;
            end
            next_col = ceil(next_s/obj.row);
            next_state = [next_row,next_col];
        end
        
        function h = show_transition(obj,cur_state,action)
            %show_transition Plot the transition on top of the maze
            % show_transition(obj,cur_state,action) plots the current state
            % as a red dimond, and the next state as a black dot
            %
            % NOTE: the Y-axis is reversed, and the first of the two
            % coordinates is actually corresponding to the column number in
            % the grid, and the second of the two coordinates is actually
            % corresponding to the row number in the grid.
            
            next_state = obj.transition(cur_state,action);
            h = figure();
            obj.show_maze(h);
            hold on;
            text(cur_state(2),cur_state(1),'\diamondsuit','HorizontalAlignment','Center','color','r');
            plot(next_state(2),next_state(1),'k.');
        end
        
        function show_path(obj,action_hist,h)
            %show_path Replays a path by following an action history
            % Input:
            % action_hist: nx1 int array, action history of 1,2,3,4
            % h: figure handle
            state_list = zeros(length(action_hist)+1,2); % initialize
            cur_state = [1,1]; % initialize as the start point
            state_list(1,:) = cur_state;
            for i = 1:length(action_hist)
                next_state = obj.transition(cur_state,action_hist(i));
                state_list(i+1,:) = next_state;
                cur_state = next_state; % update cur_state
            end
            figure(h);
            plot(state_list(1:end-1,2),state_list(1:end-1,1),'k.');
            hold on;
            plot(state_list(end,2),state_list(end,1),'ko'); % emphasize the last point
        end
        
        function show_maze(obj,h)
            figure(h)
            line([.5,obj.col+.5],[.5,.5]) % draw top border
            line([.5,obj.col+.5],[obj.row+.5,obj.row+.5]) % draw bottom border
            line([.5,.5],[1.5,obj.row+.5]) % draw left border
            line([obj.col+.5,obj.col+.5],[.5,obj.row-.5])  % draw right border
            for ii=1:length(obj.ptr_right)
                if obj.ptr_right(ii)>0 % right passage blocked
                    line([obj.cc(ii)+.5,obj.cc(ii)+.5],[obj.rr(ii)-.5,obj.rr(ii)+.5]);
                    hold on
                end
                if obj.ptr_down(ii)>0 % down passage blocked
                    line([obj.cc(ii)-.5,obj.cc(ii)+.5],[obj.rr(ii)+.5,obj.rr(ii)+.5]);
                    hold on
                end

            end
            axis equal
            axis([.5,obj.col+.5,.5,obj.row+.5])
            axis off
            set(gca,'YDir','reverse')
        end
    end
    
    methods(Static)
        function move_spot(src,evnt)
            assignin('caller','key',evnt.Key)
        end
    end
end

