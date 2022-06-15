classdef dfsCls < handle
    %dfsCls A class for depth-first search algorithm and its utilities
    %   This class contains the dfs algorithm. By structure, it requires
    %   the existence of a problem class object obj.problem that has the
    %   following:
    %   1. A property called action_space, which contains all actions
    %   2. A method called transition(), which produces next states
    
    properties
        problem % a specific problem that contains a state transition method
        e_list = {}; % nx2 cell array, exploration list, contains states and action history
        v_list = []; % nxm double array, visited state list, each state has m parameters
    end
    
    methods
        function obj = dfsCls(problem)
            %dfsCls Constructs a dfs algorithm object with a problem
            % dfsCls(problem) constructs a dfs object with a problem
            % object. The problem object can be any object with a
            % transition method. By default it is chosen as the maze
            % problem (mazeCls) modified from Rodney Meyer's implementation
            obj.problem = problem;
        end
        
        function final_path = dfs(obj,start,goal)
            %dfs The DFS algorithm
            % Inputs: grid, start, end
            % Output: final_path
            
            obj.e_list = {}; % clear e_list
            obj.v_list = []; % clear v_list
            obj.Eappend(start,[]);
            final_path = [];

            while (~isempty(obj.e_list) && isempty(final_path))
              [cur_state, cur_path] = obj.Epop();
%               [cur_state, cur_path] = obj.unpack(current);
              if cur_state == goal
                  final_path = cur_path;
              elseif ~isVisited(obj,cur_state)
                  obj.Vappend(cur_state);
                  for a = obj.problem.action_space
                      next_state = obj.transition(cur_state,a);
                      if ~isVisited(obj,next_state)
                          next_path = cur_path;
                          next_path(end+1) = a;
                          obj.Eappend(next_state,next_path);
                      end
                  end
              end
            end
        end
        
        function next_state = transition(obj,cur_state,action)
            %transition Produces the next state from current state and
            %action
            % transition(obj,cur_state,action) calls the transition method
            % in the problem object to produce a next state
            
            next_state = obj.problem.transition(cur_state,action);
        end
        
        function in = isVisited(obj,state)
            %isVisited Determines if a state is in the visited list
            % isVisited(obj,state) uses an improved version of ismember()
            % to customly determine if a state is in the visited list
            
            if isempty(obj.v_list)
                in = false;
            else
                in = ismember(state,obj.v_list,'rows');
            end
        end
        
        function [pop_state,pop_action_hist] = Epop(obj)
            %Epop Pops out an element in the exploration list
            % The expansion list e_list is an nx2 cell array, and each Epop
            % operation extracts the last state and the last action history
            % This function resembles the pop() method in Python
            if isempty(obj.e_list)
                pop_state = [];
                pop_action_hist = [];
            else
                pop_state = obj.e_list{end,1};
                pop_action_hist = obj.e_list{end,2};
                if size(obj.e_list,1) == 1 % only one element left
                    obj.e_list = {}; % empty the list
                else
                    obj.e_list(end,:) = []; % remove the popped
                end
            end
        end
        
        function Eappend(obj,state,action_hist)
            %Eappend Appends a state-action_history pair to e_list
            % Eappend(obj,state,action_hist) ands a state-action_history
            % pair to the end of e_list
            %
            % e_list is a nx2 cell array, the first column is the state,
            % the second column is the action history
            if isempty(obj.e_list)
                obj.e_list{1,1} = state;
                obj.e_list{1,2} = action_hist;
            else
                obj.e_list{end+1,1} = state;
                obj.e_list{end,2} = action_hist; % do not use end+1 again
            end
        end
        
        function Vappend(obj,state)
            %Vapend Appends a state to v_list
            % Vapend(obj,state) adds a state to the end of v_list
            obj.v_list(end+1,:) = state;
        end

    end
    
    methods(Static)
        function [state, path] = unpack(e_entry)
            %unpack Unpacks an entry in the exploration list
            % unpack(e_entry) unpacks an exploration list entry into a
            % state and an action history since initial state
            % Input:
            % e_entry: 1x2 cell array, state and path history
            % Outputs:
            % state: multidim array, problem specific state format
            % path: multidim array, problem specific action history
            
            state = e_entry(1);
            path = e_entry(2);
        end
    end
end

