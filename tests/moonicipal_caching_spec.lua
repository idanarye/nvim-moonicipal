describe('Moonicipal caching', function()
    local with = require'plenary.context_manager'.with

    local moonicipal = require'moonicipal'

    before_each(BeforeTestCleanup)

    it('cached result', function()
        SetTasksFileTasks[[
        function T:test_cached_result()
            return self:cache_result(function()
                OUTPUT = OUTPUT + 1
            end)
        end

        function T:test_task()
            T:test_cached_result()
        end
        ]]
        OUTPUT = 1
        vim.cmd.MC('test_task')
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, 2)
        OUTPUT = 1
        vim.cmd.MC('test_cached_result')
        vim.cmd.MC('test_cached_result')
        assert.are.same(OUTPUT, 3)
    end)

    it('caches buffer', function()
        SetTasksFileTasks[[
        function T:test_cached_buffer()
            return self:cached_buf_in_tab(function()
                vim.cmd.new()
                moonicipal.fake_scratch_buffer()
                CACHED_BUF_NUMBER = vim.api.nvim_buf_get_number(0)
                return vim.api.nvim_buf_get_number(0)
            end)
        end

        function T:test_task()
            local bufnr = T:test_cached_buffer()
            OUTPUT = moonicipal.get_buf_contents(bufnr)
        end
        ]]
        vim.cmd.MC('test_cached_buffer')
        moonicipal.set_buf_contents(CACHED_BUF_NUMBER, 'foo')
        OUTPUT = nil
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, 'foo')
    end)

    it('caches selection', function()
        SetTasksFileTasks[[
        function T:test_cached_choice()
            local cc = self:cached_choice{key = tostring}
            cc('foo')
            cc('bar')
            cc('baz')
            return cc:select()
        end

        function T:test_task()
            OUTPUT = T:test_cached_choice()
        end
        ]]
        local on_choice_fn
        with(Override(vim.ui, {
            select = function(opts, _, on_choice)
                on_choice_fn = function(choice_nr)
                    on_choice(opts[choice_nr], choice_nr)
                end
            end,
        }), function()
            vim.cmd.MC('test_cached_choice')
            on_choice_fn(2)

            OUTPUT = nil
            vim.cmd.MC('test_task')
            assert.are.same(OUTPUT, 'bar')

            OUTPUT = nil
            vim.cmd.MC('test_task')
            assert.are.same(OUTPUT, 'bar')

            vim.cmd.MC('test_cached_choice')
            on_choice_fn(3)
            OUTPUT = nil
            vim.cmd.MC('test_task')
            assert.are.same(OUTPUT, 'baz')
        end)
    end)

    it('caches data cell', function()
        SetTasksFileTasks[[
        function T:test_cached_data_cell()
            return self:cached_data_cell {
                buf_init = 'set buftype=nowrite',
                default = 'foo',
            }
        end

        function T:test_task()
            OUTPUT = T:test_cached_data_cell()
        end
        ]]
        vim.cmd.MC('test_cached_data_cell')
        OUTPUT = nil
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, 'foo')

        moonicipal.set_buf_contents(0, 'bar')
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, 'bar')

        moonicipal.set_buf_contents(0, 'baz')
        vim.cmd.close()
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, 'baz')

        vim.cmd.MC('test_cached_data_cell')
        vim.cmd.bdelete()
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, '')
    end)
end)
