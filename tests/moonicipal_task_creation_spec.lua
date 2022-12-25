describe('Moonicipal task creation', function()
    before_each(BeforeTestCleanup)
    it('creates a task', function()
        vim.cmd.MCe('test_task')
        vim.cmd.startinsert()
        vim.api.nvim_buf_set_text(0, -2, 4, -2, 4, {'OUTPUT = {"foo"}'})
        vim.cmd.write()
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, {'foo'})
    end)

    it('edit a task', function()
        SetTasksFileTasks[[
        function T:test_task()
            OUTPUT = {"foo"}
        end
        ]]
        vim.cmd.MCe('test_task')
        vim.api.nvim_buf_set_lines(0, -2, -2, true, {'table.insert(OUTPUT, "bar")'})
        vim.cmd.write()
        vim.cmd.MC('test_task')
        assert.are.same(OUTPUT, {'foo', 'bar'})
    end)
end)
