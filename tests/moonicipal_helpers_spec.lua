describe('Moonicipal helpers', function()
    local with = require'plenary.context_manager'.with

    before_each(BeforeTestCleanup)

    it('sleep', function()
        SetTasksFileTasks[[
        function T:test_task()
            OUTPUT = {'foo'}
            moonicipal.sleep(10)
            table.insert(OUTPUT, 'bar')
        end
        ]]
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, {'foo'})
        Sleep(20)
        assert.are.same(OUTPUT, {'foo', 'bar'})
    end)

    it('coroutine supporeted input', function()
        SetTasksFileTasks[[
        function T:test_task()
            OUTPUT = moonicipal.input()
        end
        ]]
        local on_confirm_fn
        with(Override(vim.ui, {
            input = function(_, on_confirm)
                on_confirm_fn = on_confirm
            end,
        }), function()
            OUTPUT = nil
            vim.cmd.MC('test_task')
            on_confirm_fn('foo')
            assert.are.same(OUTPUT, 'foo')
        end)
    end)

    it('coroutine supporeted select', function()
        SetTasksFileTasks[[
        function T:test_task()
            OUTPUT = moonicipal.select{'foo', 'bar', 'baz'}
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
            OUTPUT = nil
            vim.cmd.MC('test_task')
            on_choice_fn(1)
            assert.are.same(OUTPUT, 'foo')
            vim.cmd.MC('test_task')
            on_choice_fn(2)
            assert.are.same(OUTPUT, 'bar')
            vim.cmd.MC('test_task')
            on_choice_fn(3)
            assert.are.same(OUTPUT, 'baz')
        end)
    end)
end)
