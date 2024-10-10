describe('Moonicipal library import', function()
    local with = require'plenary.context_manager'.with

    local moonicipal = require'moonicipal'

    before_each(BeforeTestCleanup)

    function GenerateLibrary()
        local L = moonicipal.tasks_lib()

        function L:set_output()
            OUTPUT = 'This is the output'
        end

        return L
    end

    it('import without configuration', function()
        SetTasksFileTasks[=[
        moonicipal.import(GenerateLibrary)
        ]=]
        OUTPUT = nil
        vim.cmd.MC('set_output')
        assert.are.same(OUTPUT, 'This is the output')
    end)

    it('import in namespace', function()
        SetTasksFileTasks[=[
        -- moonicipal.import(GenerateLibrary, {
            -- namespace = 'some_namespace',
        -- })
        moonicipal.include('some_namespace', GenerateLibrary())

        function T:set_output()
            OUTPUT = 'This is the non-namespaced output'
        end
        ]=]
        OUTPUT = nil
        vim.cmd.MC('set_output')
        assert.are.same(OUTPUT, 'This is the non-namespaced output')
        vim.cmd.MC('some_namespace::set_output')
        assert.are.same(OUTPUT, 'This is the output')
    end)

    function GenerateLibraryWithConfiguration()
        local L = moonicipal.tasks_lib()
        local cfg = {
            text = nil,
        }

        function L:set_output()
            OUTPUT = cfg.text
        end

        return L, cfg
    end

    it('import with configuration', function()
        SetTasksFileTasks[=[
        local _, cfg = moonicipal.import(GenerateLibraryWithConfiguration)

        cfg.text = 'This text is configured'
        ]=]
        OUTPUT = nil
        vim.cmd.MC('set_output')
        assert.are.same(OUTPUT, 'This text is configured')
    end)
end)
