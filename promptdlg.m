classdef promptdlg < handle
    %PROMPTDLG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        totalWidth = 360;
        totalHeight = 500;
    end
    
    methods
        function obj = promptdlg(varargin)
            %PROMPTDLG Construct an instance of this class
            %   Detailed explanation goes here

            if nargin > 0
                if isgraphics(varargin{1}, 'figure')
                end
            end

            % get screensize and determine proper figure position
            if isempty(obj.fig)
                scz = get(0, 'ScreenSize');               % put the window in the center of the screen
                scx = round(scz(3)/2-obj.totalWidth/2);    % (this will usually work fine, except on some  
                scy = round(scz(4)/2-obj.totalWidth/2);    % multi-monitor setups)   
            else
                scx = round(figPos(1) + figPos(3)/2-obj.totalWidth/2);
                scy = round(figPos(2) + figPos(4)/2-obj.totalWidth/2);
            end

            obj.fig = figure(...
             'position'        , [scx, scy, obj.totalWidth, obj.totalHeight],...% figure position
             'visible'         , 'off',...         % Hide the dialog while in construction
             'backingstore'    , 'off',...         % DON'T save a copy in the background         
             'resize'          , 'off', ...        % but just keep it resizable
             'units'           , 'pixels',...      % better for drawing
             'DockControls'    , 'off',...         % force it to be non-dockable
             'name'            , 'Settings',...         % dialog title
             'menubar'         , 'none', ...       % no menubar
             'toolbar'         , 'none', ...       % no toolbar
             'NumberTitle'     , 'off',...
             'CloseRequestFcn' , '');% funcio per tancar
        end
    end
end

